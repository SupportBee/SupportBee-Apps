require 'sinatra/base'
require 'sinatra-initializers'

class RunApp < Sinatra::Base
  
  register Sinatra::Initializers

  def self.setup(app_class)
    get "/#{app_class.slug}" do
      config = app_class.configuration
      response = {:name => config['name'], :slug => config['slug'], :description => config['description']}
      content_type :json
      {app_class.slug => response}.to_json
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

    post "/#{app_class.slug}/event/:event" do
      data, payload = parse_request
      event = params[:event]
      if app = app_class.trigger_event(event, data, payload)
        "OK"
      end
    end

    post "/#{app_class.slug}/action/:action" do
      data, payload = parse_request
      action = params[:action]
      if app = app_class.trigger_action(action, data, payload)
        "OK"
      end
    end

    unless PLATFORM_ENV == 'production'
      get "/#{app_class.slug}/console" do
        @app_name = app_class.name
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
      config = app.configuration
      apps[app.slug] = {:name => config['name'], :slug => config['slug'], :description => config['description']}
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

  run! if app_file == $0
end
