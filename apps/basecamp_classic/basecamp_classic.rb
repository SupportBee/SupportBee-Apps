module BasecampClassic
  module ActionHandler
    def button
      http.basic_auth(settings.api_token,"")

      begin
        result = create_message(payload.overlay.title, payload.overlay.description)
        if result
          return [200, "Ticket sent to Basecamp Classic"]
        else
          return [500, "Ticket not sent. Please check the settings of the app"]
        end
      rescue Exception => e
        ErrorReporter.report(e)
        return [500, e.message]
      end
    end
  end
end

module BasecampClassic
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Enter Subdomain'
    string :api_token, :required => true, :label => 'Enter API token'
    string :project_id, :required => true, :label => 'Enter Project ID'

    private

    def create_message(title, body)
      response = http.post "https://#{settings.subdomain}.basecamphq.com/projects/#{settings.project_id}/posts.json" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {post:{title:title, body:body}}.to_json
      end
      response.status == 201 ? true : false
    end

  end
end
