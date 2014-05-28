module Teamwork
  module ActionHandler
    def button
      ticket = payload.tickets.first
      html = ''
      begin
        result = 
          case payload.overlay.type
          when 'message'
            response = create_message
            html = message_html_comment(response.body['id'], response.body['subject']) if response and response.body
            response
          when 'todo_list'
            response = create_todo_list
            html = todolist_html_comment(response.body['id'], response.body['name']) if response and response.body
            response
          when 'todo_item'
            response = create_todo_item
            html = todo_html_comment(response.body['todolist_id'], 'Todo item created') if response and response.body
            response
          end
        
        return [500, '{"error": "Ticket not sent. Please check the settings of the app"}'] unless result 
        comment_on_ticket(ticket, html)
        return [200, '{"message": "Ticket sent to Teamwork"}']
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")
        return [500, {message: e.message}]
      end
    end

    def projects
      [200, fetch_projects]
    end

    def todo_lists
      [200, fetch_todo_lists]
    end

    def project_accesses
      [200, fetch_project_accesses]
    end
  end
end

module Teamwork
  class Base < SupportBeeApp::Base
    
    string :token, 
      required: true, 
      label: 'Enter Your Teamwork Auth Token', 
      hint: 'Your API token can be found by logging into your TeamworkPM account, clicking your avatar in the top right and choosing Edit my details. On the API tab of the dialog click the "Show your token" at the bottom (under "API Authentication tokens").'

    def validate
      
      return true if validate_api_token
      errors[:token] = ["The API Token doesn't look right"]
      false
    end
    
    def validate_api_token
      account_details_req = teamwork_get(authentication_url)
      if account_details_req.success?
        store.set 'URL', url = (JSON.parse(account_details_req.body))["account"]["URL"]
        return true 
      end
      return false
    end

    def authentication_url
      'https://authenticate.teamwork.com/authenticate.json'
    end

    def account_url
      store.get 'URL'
    end

    def api_url(resource)
      "#{account_url}#{resource}.json"

    end

    def teamwork_get(url)
      conn = Faraday.new(:url => url)
      conn.basic_auth(settings.token, "any_password_will_do")
      conn.get 
    end

    def token
      settings.token
    end

    def project_id
      payload.overlay.projects_select
    end

    def todolist_id
      payload.overlay.todo_lists
    end

    def title
      payload.overlay.title rescue nil
    end

    def description
      payload.overlay.description rescue nil
    end

    def assignee_id
      payload.overlay.assign_to
    end
    
    private

    def projects_url
      api_url("projects")
    end

    def project_url
      api_url("projects/#{project_id}")
    end

    def project_accesses_url
      project_url.join('accesses')
    end

    def project_messages_url
      project_url.join('messages')
    end

    def project_todolists_url
      api_url("projects/#{project_id}/todo_lists")
    end

    def project_todolist_todos_url
      project_todolists_url.join(todolist_id.to_s, 'todos')
    end

    def basecamp_post(url, body)
      http.post "#{url.to_s}.json" do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['Content-Type'] = 'application/json'
        req.body = body
      end 
    end

    def create_message
      post_body = {
        subject: title, 
        content: description 
      }.to_json 

      response = basecamp_post(project_messages_url, post_body)
      response.status == 201 ? response : false
    end
    
    def create_todo_list
      _description = description.blank? ? '' : description

      post_body = {
        name: title, 
        description: _description 
      }.to_json

      response = basecamp_post(project_todolists_url, post_body)
      response.status == 201 ? response : false
    end

    def create_todo_item
      post_body = {
        content: title
      }
      post_body[:assignee] = {
        id: assignee_id,
        type: 'Person'
      } if assignee_id and assignee_id != 'none'
      post_body = post_body.to_json

      response = basecamp_post(project_todolist_todos_url, post_body)
      response.status == 201 ? response : false
    end

    def fetch_projects
      response = teamwork_get(projects_url)
      ((JSON.parse response.body)['projects']).to_json
    end

    def fetch_todo_lists
      response = teamwork_get(project_todolists_url)
      puts response.body
      ((JSON.parse response.body)['todo-lists']).to_json
    end

    def fetch_project_accesses
      response = teamwork_get(project_accesses_url)
      response.body.to_json
    end

    def todolist_html_comment(_todolist_id, _todolist_name)
      "Teamwork To-do List created!<br/> <a href='https://basecamp.com/#{settings.app_id}/projects/#{project_id}/todolists/#{_todolist_id}'>#{_todolist_name}</a>"
    end
    
    def todo_html_comment(_todolist_id, _todolist_name)
      "Teamwork todo created in the list <a href='https://basecamp.com/#{settings.app_id}/projects/#{project_id}/todolists/#{_todolist_id}'>#{_todolist_name}</a>"
    end

    def message_html_comment(_message_id, subject)
      "Teamwork message created!<br/> <a href='https://basecamp.com/#{settings.app_id}/projects/#{project_id}/messages/#{_message_id}'>#{subject}</a>"
    end
   
    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end

