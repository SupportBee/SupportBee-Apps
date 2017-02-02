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
    # Don't cache static assets (like app icon images) in development env.
    #
    # Even with this, if you change an app's icon, you still have to
    # stop and start the app platform for it to pick up the new app icon.
    set :static_cache_control, [:"no-cache"]
  end

  before do
    return if PLATFORM_ENV == 'development'
    x_supportbee_key = request.env['HTTP_X_SUPPORTBEE_KEY'] ? request.env['HTTP_X_SUPPORTBEE_KEY'] : ''
    return if x_supportbee_key == SECRET_CONFIG['key']
    halt 403, { 'Content-Type' => 'application/json' }, '{"error" : "Access forbidden"}'
  end

  def self.setup(app_class)
    get "/#{app_class.slug}" do
      content_type :json
      {app_class.slug => app_class.api_hash}.to_json
    end

    get "/#{app_class.slug}/schema" do
      response = app_class.schema
      content_type :json
      {app_class.slug => response}.to_json
    end

    get "/#{app_class.slug}/config" do
      response = app_class.configuration
      content_type :json
      {app_class.slug => response}.to_json
    end

    post "/#{app_class.slug}/valid" do
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
      data, payload = parse_request
      event = params[:event]
      if app_class.trigger_event(event, data, payload)
        status 204
      else
        status 500
      end
    end

    post "/#{app_class.slug}/action/:action" do
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
    apps = {}
    SupportBeeApp::Base.apps.each do |app|
      next if app.access == 'test'
      apps[app.slug] = app.api_hash
    end
    content_type :json
    {:apps => apps}.to_json
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

  run! if app_file == $0
end
