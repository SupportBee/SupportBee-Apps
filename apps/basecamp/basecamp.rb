module Basecamp
  module ActionHandler
    def button
      ticket = payload.tickets.first
      html = ''
      response =
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

      if response
        comment_on_ticket(ticket, html)
        show_success_notification "Ticket sent to Basecamp"
      else
        show_error_notification "Ticket not sent. Please check the settings of the app"
      end
    end

    def projects
      fetch_projects
    end

    def todo_lists
      [200, fetch_todo_lists]
    end

    def project_accesses
      [200, fetch_project_accesses]
    end
  end
end

module Basecamp
  class Base < SupportBeeApp::Base
    oauth  :basecamp,
      oauth_options: {
        expiration: :never,
        scope: "read,write"
      }

    string :app_id,
      required: true,
      label: 'Enter App ID',
      hint: 'If your basecamp URL is "https://basecamp.com/9999999" enter "9999999"'

    def validate
      # status, projects = fetch_projects
      # errors[:flash] = ["Could not connect to Basecamp with your App ID, kindly recheck."] unless status == 200
      # errors.empty? ? true : false
      response = basecamp_get(projects_url)
      return true if response.status == 200

      e = StandardError.new("Failed to fetch basecamp projects")
      context = {
        response_status: response.status,
        response_body: response.body
      }
      ErrorReporter.report(e, context: context)
      errors[:flash] = response.body
      return false
    end

    private

    def token
      settings.oauth_token || settings.token
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

    def base_url
      Pathname.new("https://basecamp.com/#{settings.app_id}").join('api', 'v1')
    end

    def projects_url
      base_url.join("projects")
    end

    def project_url
      projects_url.join(project_id.to_s)
    end

    def project_accesses_url
      project_url.join('accesses')
    end

    def project_messages_url
      project_url.join('messages')
    end

    def project_todolists_url
      project_url.join('todolists')
    end

    def todolist_todos_url
      project_todolists_url.join(todolist_id.to_s, 'todos')
    end

    def todo_item_comments_url(id)
      project_url.join('todos', id.to_s, 'comments')
    end

    def basecamp_post(url, body)
      http.post "#{url.to_s}.json" do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['Content-Type'] = 'application/json'
        req.body = body
      end
    end

    def basecamp_get(url)
      response = http.get "#{url.to_s}.json" do |req|
       req.headers['Authorization'] = 'Bearer ' + token
       req.headers['Accept'] = 'application/json'
      end
    end

    def create_message
      body = {
        subject: title,
        content: description
      }.to_json

      response = basecamp_post(project_messages_url, body)
      response.status == 201 ? response : false
    end

    def create_todo_list
      _description = description.blank? ? '' : description

      body = {
        name: title,
        description: _description
      }.to_json

      response = basecamp_post(project_todolists_url, body)
      response.status == 201 ? response : false
    end

    def create_todo_item
      body = {
        content: title
      }
      body[:assignee] = {
        id: assignee_id,
        type: 'Person'
      } if assignee_id and assignee_id != 'none'
      body = body.to_json

      create_todo_item_response = basecamp_post(todolist_todos_url, body)
      return false if create_todo_item_response.status != 201
      todo_item_id = create_todo_item_response.body['id']
      create_comment_url = todo_item_comments_url(todo_item_id)
      create_comment_response = basecamp_post(create_comment_url, {content: description}.to_json)
      create_comment_response.status == 201 ? create_todo_item_response : false
    end

    def fetch_projects
      response = basecamp_get(projects_url)
      [response.status, response.body.to_json]
    end

    def fetch_todo_lists
      response = basecamp_get(project_todolists_url)
      response.body.to_json
    end

    def fetch_project_accesses
      response = basecamp_get(project_accesses_url)
      response.body.to_json
    end

    def todolist_html_comment(_todolist_id, _todolist_name)
      "Basecamp To-do List created!<br/> <a href='https://basecamp.com/#{settings.app_id}/projects/#{project_id}/todolists/#{_todolist_id}'>#{_todolist_name}</a>"
    end

    def todo_html_comment(_todolist_id, _todolist_name)
      "Basecamp todo created in the list <a href='https://basecamp.com/#{settings.app_id}/projects/#{project_id}/todolists/#{_todolist_id}'>#{_todolist_name}</a>"
    end

    def message_html_comment(_message_id, subject)
      "Basecamp message created!<br/> <a href='https://basecamp.com/#{settings.app_id}/projects/#{project_id}/messages/#{_message_id}'>#{subject}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end
