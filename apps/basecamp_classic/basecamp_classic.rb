module BasecampClassic
  module ActionHandler
    def button
      http.basic_auth(settings.api_token,"")

      begin
        create_message(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Ticket sent to Basecamp_classic"]

    end
  end
end

module BasecampClassic
  class Base < SupportBeeApp::Base
    string :account_name, :required => true, :label => 'Enter Account Name'
    string :api_token, :required => true, :label => 'Enter API token'
    string :project_id, :required => true, :label => 'Enter Project ID'

    private

    def create_message(title, body)
      response = http.post "https://#{settings.account_name}.basecamphq.com/projects/10954464/posts.json" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {post:{title:title, body:body}}.to_json
      end
    end

  end
end

