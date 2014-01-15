module Basecamp
  module ActionHandler
    def button
      ticket = payload.tickets.first
      html = ''
      begin
        result = 
          case payload.overlay.type
          when 'todo_list'
            response = create_todo_list(payload.overlay.title, payload.overlay.description)
            html = todo_html_comment(response) if response
            response
          when 'message'
            response = create_message(payload.overlay.title, payload.overlay.description)
            html = message_html_comment(response) if response
            response
          end
        
        return [500, "Ticket not sent. Please check the settings of the app"] unless result 
        comment_on_ticket(ticket, html)
        return [200, "Ticket sent to Basecamp"]
      rescue Exception => e
        return [500, e.message]
      end
    end

    def projects
      [200, fetch_projects.to_json]
    end

  def todo_lists
[200, 
      fetch_todo_lists(payload.project_id)
      ]
  end
  end
end

module Basecamp
  class Base < SupportBeeApp::Base
    oauth  :"basecamp", :oauth_options => {:expiration => :never, :scope => "read,write"}
    string :app_id, :required => true, :label => 'Enter App ID', :hint => 'If your base URL is "https://basecamp.com/9999999" enter "9999999"'
    string :project_id, :required => true, :label => 'Enter Project ID', :hint => 'When you go to a project, if the URL is "https://basecamp.com/9999999/projects/8888888-explore-basecamp" enter "8888888"'
  
    private
 
    def create_message(subject, content)
      token = settings.oauth_token || settings.token
      response = http.post "https://basecamp.com/#{settings.app_id}/api/v1/projects/#{settings.project_id}/messages.json" do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['Content-Type'] = 'application/json'
        req.body = {subject:subject, content:content}.to_json 
      end   
      response.status == 201 ? response : false
    end
    
    def create_todo_list(subject, content)
      token = settings.oauth_token || settings.token
      response = http.post "https://basecamp.com/#{settings.app_id}/api/v1/projects/#{settings.project_id}/todolists.json" do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['Content-Type'] = 'application/json'
        req.body = {name:subject, description:content}.to_json 
      end
      response.status == 201 ? response : false
    end

    def fetch_projects
      token = settings.oauth_token || settings.token
      response = http.get "https://basecamp.com/#{settings.app_id}/api/v1/projects" do |req|
       req.headers['Authorization'] = 'Bearer ' + token
       req.headers['Accept'] = 'application/json'
      end
      response.body
    end

    def fetch_todo_lists(project_id)
      token = settings.oauth_token || settings.token
      response = http.get "https://basecamp.com/#{settings.app_id}/api/v1/projects/#{project_id}/todolists.json" do |req|
       req.headers['Authorization'] = 'Bearer ' + token
       req.headers['Accept'] = 'application/json'
      end
      response.body.to_json
    end
    def todo_html_comment(response)
      "Basecamp todo created!\n <a href='https://basecamp.com/#{settings.app_id}/projects/#{settings.project_id}/todolists/#{response.body['id']}'>#{response.body['name']}</a>"
    end
    
    def message_html_comment(response)
      "Basecamp message created!\n <a href='https://basecamp.com/#{settings.app_id}/projects/#{settings.project_id}/messages/#{response.body['id']}'>#{response.body['subject']}</a>"
    end
   
    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end

