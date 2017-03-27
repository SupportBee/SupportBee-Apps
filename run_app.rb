require 'sinatra/base'
require 'sinatra-initializers'

class RunApp < Sinatra::Base
  register Sinatra::Initializers

  unless PLATFORM_ENV == 'production'
    enable :logging
    enable :dump_errors
    enable :show_exceptions
  end

  if PLATFORM_ENV == 'development'
    # Tell browsers to not cache static assets (like app icons) in development env
    #
    # @note If you change an app's icon, stop and the start the app platform for
    # it to pick up the new icon
    set :static_cache_control, [:"no-cache"]
  end

  def self.setup(app_class)
    get "/#{app_class.slug}" do
      protected_by :secret_key

      content_type :json
      { app_class.slug => app_class.api_hash }.to_json
    end

    get "/#{app_class.slug}/schema" do
      protected_by :secret_key

      response = app_class.schema

      content_type :json
      { app_class.slug => response }.to_json
    end

    get "/#{app_class.slug}/config" do
      protected_by :secret_key

      response = app_class.configuration

      content_type :json
      { app_class.slug => response }.to_json
    end

    post "/#{app_class.slug}/valid" do
      protected_by :secret_key

      data, payload = parse_request
      response = {}
      app = app_class.new(data, payload)

      if app.valid?
        status 200
      else
        status 400
        response = app.errors
      end
      content_type :json
      { errors: response }.to_json
    end

    post "/#{app_class.slug}/event/:event" do
      protected_by :secret_key

      app_slug = app_class.slug
      event = params[:event]
      data, payload = parse_request

      # The webhook app receives a lot of traffic. Process web hook events
      # in a different queue with lower priority.
      queue = (app_slug == "webhook") ? "webhook_app_events" : "app_events"
      Sidekiq::Client.push("class" => TriggerAppEvent, "queue" => queue, "args" => [app_slug, event, data, payload])

      status 204
    end

    post "/#{app_class.slug}/action/:action" do
      protected_by :secret_key

      data, payload = parse_request
      action = params[:action]
      begin
        result = app_class.trigger_action(action, data, payload)
        status result[0]
        body result[1] if result[1]
      rescue Exception => e
        context = { app_slug: app_class.slug, action: action, data: data, payload: payload }
        ErrorReporter.report(e, context: context)
        status 500
      end
    end

    unless PLATFORM_ENV == 'production'
      get "/#{app_class.slug}/console" do
        protected_by :secret_key

        @app_name = app_class.name
        @app_slug = app_class.slug
        @schema = app_class.schema
        @config = app_class.configuration
        haml :console
      end
    end
  end

  SupportBeeApp::Base.apps.each do |app|
    app.setup_for(self)
  end

  get "/" do
    protected_by :secret_key

    apps = {}
    SupportBeeApp::Base.apps.each do |app|
      next if app.access == 'test'
      apps[app.slug] = app.api_hash
    end

    content_type :json
    { :apps => apps }.to_json
  end

  get "/system_status/pingdom" do
    protected_by :http_basic_auth

    pending_jobs_count = Sidekiq::Stats.new.enqueued
    if pending_jobs_count > 500
      status = "CHOCKED - TOO MANY PENDING JOBS IN SIDEKIQ"
    else
      status = "OK"
    end

    content_type :xml
    to_xml({
      pingdom_http_custom_check: {
        status: status,
        response_time: 1
      }
    })
  end

  run! if app_file == $0

  private

  def protected_by(auth_strategy)
    return if PLATFORM_ENV == 'development'

    if auth_strategy == :http_basic_auth
      protected_by_http_basic_auth
    else
      protected_by_secret_key
    end
  end

  def protected_by_http_basic_auth
    # Borrowed from http://www.sinatrarb.com/faq.html#auth
    auth = Rack::Auth::Basic::Request.new(request.env)
    if auth.provided? && auth.basic? && auth.credentials && auth.credentials[1] == SECRET_CONFIG['key']
      return
    end

    halt_with_403
  end

  def protected_by_secret_key
    x_supportbee_key = request.env['HTTP_X_SUPPORTBEE_KEY'] ? request.env['HTTP_X_SUPPORTBEE_KEY'] : ''
    return if x_supportbee_key == SECRET_CONFIG['key']

    halt_with_403
  end

  def halt_with_403
    halt 403, { 'Content-Type' => 'application/json' }, '{"error" : "Access forbidden"}'
  end

  def parse_request
    parse_json_request
  end

  def parse_json_request
    req = JSON.parse(request.body.read)
    [req['data'], req['payload']]
  end

  def self.logger
    LOGGER
  end

  def logger
    self.class.logger
  end

  def to_xml(hash)
    Gyoku.xml(hash, key_converter: :none)
  end
end
