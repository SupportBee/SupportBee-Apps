module Unfuddle
  module ActionHandler
    def button      
      http.basic_auth(settings.username, settings.password)
      begin
        create_message(payload.overlay.title,payload.overlay.body)
      rescue  Exception => e
        return [500, e.message]          
      end
      [200, "Message successfully created on Unfuddle"]
    end
  end
end

module Unfuddle
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Subdomain' # , :hint => 'Tell me your name'
    string :username, :required => true, :label => 'Username'
    password :password, :required => true    
    string :project_id, :required => true, :label => 'Enter Project ID'    
    boolean :use_ssl, :default => true, :label => 'Use SSL'

    private

    def create_message(title, body)
      response = http.post "https://#{settings.subdomain}.unfuddle.com/api/v1/projects/#{settings.project_id}/messages.json" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {message:{title:title, body:body}}.to_json
      end
      response.status == 201 ? true : false
    end

    white_list :subdomain, :username, :use_ssl, :project_id
  end
end

