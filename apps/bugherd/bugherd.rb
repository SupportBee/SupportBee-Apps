module Bugherd
  module ActionHandler
    def button
      http_basic_auth(settings.token, "")
      begin
        ticket = payload.ticket.first
        task = create_task(ticket, payload.overlay.description)
        return [500, task['error'].capitalize!] if task['error']
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
  class ProjectNotFound < ::StandardError
    def message
      "Cannot find Project"
    end
  end

  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'Bugherd Api Key', :hint => 'Login to your Bugherd account, go to Settings > General Settings'
    string :project_id, :required => true, :label => 'Project ID' 

    def create_task(ticket, description)
      project_id = settings.project_id
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
      raise ProjectNotFound if response.status == 404
      send_comment(ticket, response.body) if response.status == 201
      response.body    
    end

    def task_info_html(ticket, task)
      "Bugherd Task Created!\n <a href='#{task['task']['admin_link']}'>#{ticket.subject}</a>"
    end
    
    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

    def send_comment(ticket, task)
      task_id = task['task']['id']
      project_id = task['task']['project_id']
      http_post "https://www.bugherd.com/api_v2/projects/#{project_id}/tasks/#{task_id}/comments.json" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          "comment" => {
            "text" => generate_comment_content(ticket)
          }
        }.to_json
      end
    end

    def generate_comment_content(ticket)
      "#{ticket.summary} \n https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end
  end
end

