module Basecamp
  module ActionHandler
    def button

      begin
        result = create_message(payload.overlay.title, payload.overlay.description)
        if result
          return [200, "Ticket sent to Basecamp"]
        else
          return [500, "Ticket not sent. Please check the settings of the app"]
        end
      rescue Exception => e
        return [500, e.message]
      end

    end
  end
end

module Basecamp
  class Base < SupportBeeApp::Base
    oauth  :"basecamp", :oauth_options => {:expiration => :never, :scope => "read,write"}
  
    private
 
    def create_message(subject, content)
      token = settings.oauth_token || settings.token
      response = http.post "https://basecamp.com/2213136/api/v1/projects/2479153/messages.json" do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['Content-Type'] = 'application/json'
        req.body = {subject:subject, content:content}.to_json 
      end
      response.status == 201 ? true : false
    end
  end
end

