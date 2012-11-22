module Asana 
  module ActionHandler
    def button

      begin
        create_task(payload.overlay.title, payload.overlay.notes)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Ticket sent to Asana"]

    end
  end
end

module Asana
  require 'json'

  class Base < SupportBeeApp::Base
    string :workspace_id, :required => true, :label => 'Workspace ID'
    string :token, :required => true, :label => 'Token'

    private

    def create_task(task_name, notes)
      http.basic_auth(settings.token, "")
      response = http_post "https://app.asana.com/api/1.0/tasks" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {:data => {:workspace => settings.workspace_id, :name => task_name, :notes => notes, :assignee => 'me'}}.to_json
      end
    end

  end
end
