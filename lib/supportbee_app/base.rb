require "addressable/uri"

module SupportBeeApp
  class Base
    include HttpHelper
    extend DSL

    class << self
      def inherited(app)
        app.send(:include, app.event_handler) if app.event_handler
        app.send(:include, app.action_handler) if app.action_handler
        SupportBeeApp::Base.apps << app
        super
      end

      def event_handler
        app_module.const_defined?("EventHandler") ? app_module.const_get("EventHandler") : nil
      end

      def action_handler
        app_module.const_defined?("ActionHandler") ? app_module.const_get("ActionHandler") : nil
      end

      attr_writer :current_sha

      def env
        @env ||= PLATFORM_ENV
      end

      %w(development test production staging).each do |m|
        define_method "#{m}?" do
          env == m
        end
      end

      def slug
        configuration['slug']
      end

      def name
        configuration['name']
      end

      def current_sha
        @current_sha ||=
          `cd #{PLATFORM_ROOT}; git rev-parse HEAD 2>/dev/null || echo unknown`.
          chomp.freeze
      end

      def apps
        @apps ||= []
      end

      def root
        Pathname.new(APPS_PATH).join(app_module.to_s.underscore)
      end

      def app_module
        self.to_s.deconstantize.constantize
      end

      def assets_path
        root.join('assets')
      end

      def javascripts_path
        assets_path.join('javascripts')
      end

      def views_path
        assets_path.join('views')
      end

      def configuration
        @configuration ||= YAML.load_file(root.join('config.yml').to_s)
      end

      def schema
        @schema ||= {}
      end

      def info
        {
          'name' => configuration['name'],
          'slug' => configuration['slug'],
          'configuration' => configuration,
          'schema' => schema
        }
      end

      def api_hash
        result = configuration.dup
        if has_actions?
          result['actions'] = result.delete('action')
          result['actions']['button'] = buttons_hash if has_action?(:button)
        end
        result['actions'] = {} unless result['actions']
        result['javascript'] = compiled_js if has_javascript?
        result['icon'] = image_url('icon.png')
        result['screenshots'] = [image_url('screenshot.png')]
        result['events'] = events
        result
      end

      def has_actions?
        !!(configuration['action'])
      end

      def has_javascript?
        return false unless Dir.exists? javascripts_path
        return false unless [coffeescript_files, javascript_files].flatten.length > 0
        true
      end

      def events
        event_methods.map {|each_method| each_method.to_s.gsub('_','.')}
      end

      def compiled_js
        javascripts = ""
        javascript_files.each do |file|
          javascripts << File.read(file)
        end
        coffeescript_files.each do |file|
          compiled = CoffeeScript.compile(File.read(file))
          javascripts << compiled
        end
        javascripts
      end

      def coffeescript_files
        Dir.glob("#{javascripts_path}/*.coffee")
      end

      def javascript_files
        Dir.glob("#{javascripts_path}/*.js")
      end

      def image_url(filename)
        Pathname(APP_CONFIG['cloudfront_base_url']).join('images', slug, filename).to_s
      end

      def has_action?(action)
        return unless has_actions?
        action = action.to_s
        actions_hash.has_key?(action)
      end

      def actions_hash
        configuration['action']
      end

      def buttons_hash
        return unless has_action?('button')
        _hash = actions_hash['button'].dup
        if _hash['overlay']
          _button_overlay_path = views_path.join('button', 'overlay.hbs')
          _hash['overlay'] = {}
          _hash['overlay']['template'] = File.read(_button_overlay_path)
          _hash['overlay']['fetch_data'] = action_methods.include?(:dynamic_data) ? true : false
        end
        _hash
      end

      def access
        configuration['access']
      end

      def white_listed
        @white_listed ||= []
      end

      def white_list(*attrs)
        attrs.each do |attr|
          white_listed << attr.to_s
        end
      end

      def add_to_schema(type,name,options={})
        type = type.to_s
        name = name.to_s

        required = options.delete(:required) ? true : false
        label = options.delete(:label) || name.humanize

        default = options.delete(:default)
        hint = options.delete(:hint)
        oauth_options = options.delete(:oauth_options)

        schema[name] = { 'type' => type, 'required' => required, 'label' => label }
        schema[name]['default'] = default if default
        schema[name]['hint'] = hint if hint
        schema[name]['oauth_options'] = oauth_options if type == "oauth" and oauth_options
        schema
      end

      def event_methods
        event_handler ? event_handler.instance_methods : []
      end

      def action_methods
        action_handler ? action_handler.instance_methods : []
      end

      def trigger_event(event, data, payload = nil)
        app = new(data,payload)
        app.trigger_event(event)
      end

      def trigger_action(action, data, payload = nil)
        app = new(data,payload)
        app.trigger_action(action)
      end

      def setup_for(sinatra_app)
        sinatra_app.setup(self)
      end

      def find_from_slug(app_slug)
        SupportBeeApp::Base.apps.detect { |app_class| app_class.slug == app_slug }
      end
    end

    self.env ||= PLATFORM_ENV

    attr_reader :data
    attr_reader :payload
    attr_reader :auth
    attr_reader :settings
    attr_reader :store
    attr_accessor :errors

    attr_writer :ca_file

    def initialize(data = {}, payload = {})
      @data = Hashie::Mash.new(data) || {}
      @auth = @data[:auth] || {}
      @settings = @data[:settings] || {}

      payload = {} if payload.blank?
      @payload = preprocess_payload(payload)

      @store = SupportBeeApp::Store.new(redis_key_prefix: redis_key_prefix)
      @errors = {}
    end

    def valid?
      return true unless self.respond_to?(:validate)
      validate
    end

    def trigger_event(event)
      @event = event
      method = to_method(event)
      begin
        response = self.send(method) if self.respond_to?(method)
        if response
          LOGGER.info log_event_message
        else
          LOGGER.warn log_event_message
        end

        return response
      rescue Exception => e
        context = { event: event }
        ErrorReporter.report(e, context: context)
        return false
      end
    end

    def trigger_action(action)
      @action = action
      method = to_method(action)
      result = []
      begin
        result = self.respond_to?(method) ? self.send(method) : [400, 'This app does not support the specified action']

        all_actions if self.respond_to?(:all_actions)
        LOGGER.info log_action_message
      rescue Exception => e
        context = { action: action }
        ErrorReporter.report(e, context: context)
        LOGGER.error log_action_message("#{e.message} \n #{e.backtrace}")
        result = [500, e.message]
      end

      LOGGER.error log_action_message("#{result[1]}") if result[0] == 500
      result
    end

    def log_message(trigger, message='')
      "[%s] %s/%s %s %s %s" % [Time.now.utc.to_s, self.class.slug, trigger, JSON.generate(log_data), auth.subdomain, message]
    end

    def log_event_message(message = '')
      log_message(@event, message)
    end

    def log_action_message(message = '')
      log_message(@action, message)
    end

    def redis_key_prefix
      "#{self.class.slug}:#{company_subdomain}"
    end

    def company_subdomain
      auth.subdomain
    end

    private

    def image_url(filename)
      self.class.image_url(filename)
    end

    def log_data
      self.class.white_listed.inject({}) do |hash, key|
        if value = settings[key]
          hash.update key => sanitize_log_value(value)
        else
          hash
        end
      end
    end

    def sanitize_log_value(value)
      string = value.to_s
      string.strip!
      if string =~ /^[a-z]+\:\/\//
        uri = Addressable::URI.parse(string)
        uri.password = "*" * uri.password.size if uri.password
        uri.to_s
      else
        string
      end
    rescue Addressable::URI::InvalidURIError
      string
    end

    def preprocess_payload(raw)
      result = Hashie::Mash.new(raw)
      raw = result.delete(:payload)
      return result unless raw

      if raw[:tickets]
        result[:tickets] = []
        raw[:tickets].each { |ticket| result[:tickets] << SupportBee::Ticket.new(auth, ticket) }
      end
      result[:ticket] = SupportBee::Ticket.new(auth, raw[:ticket]) if raw[:ticket]
      result[:reply] = SupportBee::Reply.new(auth, raw[:reply]) if raw[:reply]
      result[:company] = SupportBee::Company.new(auth, raw[:company]) if raw[:company]
      result[:comment] = SupportBee::Comment.new(auth, raw[:comment]) if raw[:comment]
      result[:agent] = SupportBee::User.new(auth, raw[:agent]) if raw[:agent]
      result[:user_assignment] = SupportBee::UserAssignment.new(auth, raw[:user_assignment]) if raw[:user_assignment]
      result[:team_assignment] = SupportBee::TeamAssignment.new(auth, raw[:team_assignment]) if raw[:team_assignment]
      result[:raw_payload] = raw
      result
    end

    # Convert event name to method name
    def to_method(string)
      return 'all_events' if respond_to?(:all_events)
      string.gsub('.', '_').underscore
    end
  end
end
