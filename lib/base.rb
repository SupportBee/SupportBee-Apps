module SupportBeeApp
	class Base
		
    include HttpHelper

    class << self
			def env
        @env ||= PLATFORM_ENV
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

      attr_writer :current_sha

      %w(development test production staging).each do |m|
      	define_method "#{m}?" do
        	env == m
      	end
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
        ['action'].each{|key| result.delete(key)}
        result['icon'] = image_url('icon.png')
        result['screenshots'] = [image_url('screenshot.png')]
        result
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

        schema[name] = { 'type' => type, 'required' => required, 'label' => label }
        schema[name]['default'] = default if default
        schema[name]['hint'] = hint if hint
        schema
    	end

    	def string(name, options={})
      	add_to_schema :string, name, options
    	end

    	def password(name, options={})
      	add_to_schema :password, name, options
    	end

    	def boolean(name, options={})
      	add_to_schema :boolean, name, options
    	end

      def token(name, options={})
        add_to_schema :token, name, options
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

      def event_handler
        app_module.const_defined?("EventHandler") ? app_module.const_get("EventHandler") : nil
      end

      def action_handler
        app_module.const_defined?("ActionHandler") ? app_module.const_get("ActionHandler") : nil
      end

    	def inherited(app)
        app.send(:include, app.event_handler) if app.event_handler
        app.send(:include, app.action_handler) if app.action_handler
      	SupportBeeApp::Base.apps << app 
      	super
    	end

    	def setup_for(sinatra_app)
    		sinatra_app.setup(self)
    	end
		end

		self.env ||= PLATFORM_ENV

    attr_reader :data
		attr_reader :payload
    attr_reader :auth
    attr_reader :settings

    attr_writer :ca_file

		def initialize(data = {}, payload = {})
    	@data = Hashie::Mash.new(data) || {}
      @auth = @data[:auth] || {}
      @settings = @data[:settings] || {}
      @payload = pre_process_payload(payload)
  	end

    def trigger_event(event)
      @event = event
      method = to_method(event)
      begin
        self.send method if self.respond_to?(method)
        all_events if self.respond_to?(:all_events)
        LOGGER.info log_event_message
      rescue Exception => e
        LOGGER.error log_event_message("#{e.message} \n #{e.backtrace}")
      end
    end

    def trigger_action(action)
      @action = action
      method = to_method(action)
      result = []

      begin
        result = self.send method if self.respond_to?(method)
        all_actions if self.respond_to?(:all_actions)
        LOGGER.info log_action_message
      rescue Exception => e
        LOGGER.error log_action_message("#{e.message} \n #{e.backtrace}")
        result = [500, e.message]
      end

      result
    end

    def log_message(trigger, message ='')
      "[%s] %s/%s %s %s %s" % [Time.now.utc.to_s, self.class.slug, trigger, JSON.generate(log_data), auth.subdomain, message]
    end

    def log_event_message(message='')
      log_message(@event, message)
    end

    def log_action_message(message='')
      log_message(@action, message)
    end

    private

    def self.image_url(filename)
      Pathname(APP_CONFIG['cloudfront_base_url']).join('images', slug, filename).to_s
    end

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

    
    def pre_process_payload(raw)
      result = Hashie::Mash.new(raw)
      raw = result.delete(:payload)
      return result unless raw

      if raw[:tickets]
        result[:tickets] = []
        raw[:tickets].each {|ticket| result[:tickets] << SupportBee::Ticket.new(auth, ticket) }
      end
      result[:ticket]  = SupportBee::Ticket.new(auth, raw[:ticket]) if raw[:ticket]
      result[:reply]   = SupportBee::Reply.new(auth, raw[:reply]) if raw[:reply]
      result[:company] = SupportBee::Company.new(auth, raw[:company]) if raw[:company]
      result[:comment] = SupportBee::Comment.new(auth, raw[:comment]) if raw[:comment]
      result
    end

    def to_method(string)
      string.gsub('.','_').underscore
    end
	end
end
