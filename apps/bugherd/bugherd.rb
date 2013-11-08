module Bugherd
  module ActionHandler
    def button
      http_basic_auth(settings.token, "")
      begin
        ticket = payload.ticket.first
        task = create_task(payload.overlay.description)
        html = task_info_html(ticket, task)
        comment_on_ticket(ticket, html)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "New Task created successfully in BugHerd"]
    end
  end
end

module Bugherd
  require 'json'
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'Bugherd Api Key', :hint => 'Login to your Bugherd account, go to Settings > General Settings'
    string :project, :required => true, :label => 'Project ID' 

    def create_task(description)
      project_id = settings.project
      response = http_post "https://www.bugherd.com/api_v2/projects/#{project_id}/tasks.json" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          "task" => {
            "description" => description,
            "priority" => "normal",
            "status" => "backlog"
          }  
        }.to_json
      end 
      response.body    
    end

    def task_info_html(ticket, task)
      "Bugherd Task Created!\n <a href='#{task['task']['admin_link']}'>#{ticket.subject}</a>"
    end
    
    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end

