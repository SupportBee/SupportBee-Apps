require "addressable/uri"

module SupportBeeApp
  class Base
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

      def find_from_slug(app_slug)
        SupportBeeApp::Base.apps.detect { |app_class| app_class.slug == app_slug }
      end
    end

    include HttpHelper
    include Api

    attr_reader :data
    attr_reader :payload
    attr_reader :auth
    attr_reader :settings
    attr_reader :store
    attr_writer :ca_file

    attr_accessor :success_notification
    attr_accessor :error_notification
    attr_accessor :inline_errors

    def initialize(data = {}, payload = {})
      @data = Hashie::Mash.new(data) || {}
      @auth = @data[:auth] || {}
      @settings = @data[:settings] || {}

      payload = {} if payload.blank?
      @payload = preprocess_payload(payload)

      @store = SupportBeeApp::Store.new(redis_key_prefix: redis_key_prefix)
      @inline_errors = {}
    end

    def valid?
      return true unless self.respond_to?(:validate)

      begin
        validate
      rescue => e
        report_exception(e)

        show_error_notification e.message
        return false
      end
    end

    def trigger_event(event)
      @event = event
      method = event_to_method_name(@event)
      return unless method

      begin
        result = self.public_send(method)
        if result == false
          LOGGER.warn log_event_message
        else
          LOGGER.info log_event_message
        end
      rescue => e
        LOGGER.warn log_event_message
        report_exception(e)
      end
    end

    def trigger_action(action)
      @action = action
      method = action_to_method_name(@action)
      return unknown_action unless method

      begin
        result = self.public_send(method)
        result = [200, success_notification] if success_notification
        result = [500, error_notification] if error_notification

        LOGGER.info log_action_message
      rescue => e
        result = [500, e.message]

        report_exception(e)
        LOGGER.error log_action_message("#{e.message} \n #{e.backtrace}")
      end

      result
    end

    def redis_key_prefix
      "#{slug}:#{company_subdomain}"
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

    # Convert event name to method nam
    def event_to_method_name(event)
      method_name = event.gsub('.', '_').underscore
      return method_name if respond_to?(method_name)
      return "all_events" if respond_to?(:all_events)
      return nil
    end

    def action_to_method_name(action)
      return action if respond_to?(action)
      return nil
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

    def unknown_action
      [400, "This app does not support the specified action"]
    end

    def error_context
      context = {
        app_slug: slug,
        company_subdomain: company_subdomain,
        payload: @payload[:raw_payload]
      }
      context[:action] = @action if @action
      context[:event] = @event if @event

      context
    end

    def error_tags
      [slug]
    end

    def slug
      self.class.slug
    end

    def company_subdomain
      auth.subdomain
    end

    def log_event_message(message = '')
      log_message(@event, message)
    end

    def log_action_message(message = '')
      log_message(@action, message)
    end

    def log_message(trigger, message='')
      "[%s] %s/%s %s %s %s" % [Time.now.utc.to_s, self.class.slug, trigger, JSON.generate(log_data), company_subdomain, message]
    end
  end
end
