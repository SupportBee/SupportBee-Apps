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
      [200, fetch_projects]
    end

    def todo_lists
      [200, fetch_todo_lists(payload.project_id)]
    end
  end
end

module Basecamp
  class Base < SupportBeeApp::Base
    oauth  :"basecamp", :oauth_options => {:expiration => :never, :scope => "read,write"}
    string :app_id, :required => true, :label => 'Enter App ID', :hint => 'If your base URL is "https://basecamp.com/9999999" enter "9999999"'
    string :project_id, :required => true, :label => 'Enter Project ID', :hint => 'When you go to a project, if the URL is "https://basecamp.com/9999999/projects/8888888-explore-basecamp" enter "8888888"'
  
    private

    def basecamp_token
      settings.oauth_token || settings.token
    end

    def base_url
      Pathname.new("https://basecamp.com/#{settings.app_id}")
    end

    def projects_url
      base_url.join("/api/v1/projects/")
    end

    def project_url(project_id)
      projects_url.join(project_id)
    end

    def project_messages_url(project_id)
      project_url(project_id).join('messages.json')
    end

    def project_todolists_url(project_id)
      project_url(project_id).join('todolists.json')
    end

    def basecamp_post(url, body)
      http.post url do |req|
        req.headers['Authorization'] = 'Bearer ' + basecamp_token
        req.headers['Content-Type'] = 'application/json'
        req.body = body
      end 
    end

    def basecamp_get(url)
      response = http.get url do |req|
       req.headers['Authorization'] = 'Bearer ' + basecamp_token
       req.headers['Accept'] = 'application/json'
      end
    end

    def create_message(subject, content)
      post_body = {subject:subject, content:content}.to_json 
      response = basecamp_post(project_messages_url(settings.project_id), post_body)
      response.status == 201 ? response : false
    end
    
    def create_todo_list(subject, content)
      post_body = {name:subject, description:content}.to_json 
      response = basecamp_post(project_todolists_url(settings.project_id), post_body)
      response.status == 201 ? response : false
    end

    def fetch_projects
      response = basecamp_get(projects_url)
      response.body.to_json
    end

    def fetch_todo_lists(project_id)
      response = basecamp_get(project_todolists_url(project_id))
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

