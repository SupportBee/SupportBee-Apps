module Basecamp3
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

        return [500, { error: "Ticket not sent. Please check the settings of the app" }.to_json] unless result
        comment_on_ticket(ticket, html)
        return [200, { message: "Ticket sent to Basecamp" }.to_json]
      rescue Exception => e
        context = ticket.context.merge(company_subdomain: payload.company.subdomain, app_slug: self.class.slug, payload: payload)
        ErrorReporter.report(e, context)
        return [500, { message: e.message}.to_json]
      end
    end

    def projects
      fetch_projects
    end

    def todo_lists
      [200, fetch_todo_lists]
    end

    def project_members
      [200, fetch_project_members]
    end
  end
end

module Basecamp3
  class Base < SupportBeeApp::Base
    oauth  :basecamp,
      oauth_options: {
        expiration: :never,
        scope: "read,write"
      }

    string :app_id,
      required: true,
      label: 'Enter App ID',
      hint: 'If your base URL is "https://basecamp.com/9999999" enter "9999999"'

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
      ErrorReporter.report(e, context)
      errors[:flash] = response.body
      return false
    end

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

    def assignee_ids
      Array(payload.overlay.assign_to)
    end

    private

    def base_url
      Pathname.new("https://3.basecampapi.com").join(settings.app_id.to_s)
    end

    def bucket_url
      base_url.join("buckets", project_id.to_s)
    end

    def projects_url
      base_url.join("projects")
    end

    def project_url
      projects_url.join(project_id.to_s)
    end

    def project_members_url
      project_url.join('people')
    end

    def project_messages_url
      project_message_board_url.join("messages")
    end

    def project_message_board_url
      response = basecamp_get(project_url)
      # @todo Raise exception in case of an http error
      dock = response.body["dock"]
      message_board = dock.select { |dock_item| dock_item["name"] == "message_board" }.first
      message_board_url = message_board["url"].chomp(".json")
      Pathname.new(message_board_url)
    end

    def project_todolists_url
      project_todoset_url.join('todolists')
    end

    def project_todoset_url
      response = basecamp_get(project_url)
      # @todo Raise exception in case of an http error
      dock = response.body["dock"]
      todoset = dock.select { |dock_item| dock_item["name"] == "todoset" }.first
      todoset_url = todoset["url"].chomp(".json")
      Pathname.new(todoset_url)
    end

    def todolist_url
      todolist_id = 
      bucket_url.join("todolists", )
    end

    def basecamp_post(url, body)
      http.post "#{url.to_s}.json" do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['User-Agent'] = "SupportBee Developers (nisanth@supportbee.com)"
        req.headers['Content-Type'] = 'application/json'
        req.body = body
      end
    end

    def basecamp_get(url)
      response = http.get "#{url.to_s}.json" do |req|
       req.headers['Authorization'] = 'Bearer ' + token
       req.headers['User-Agent'] = "SupportBee Developers (nisanth@supportbee.com)"
       req.headers['Accept'] = 'application/json'
      end
    end

    def create_message
      body = {
        subject: title,
        content: description,
        status: "active" # Publish the message immediately
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
        content: title,
        description: description
      }
      body[:assignee_ids] = assignee_ids unless assignee_ids.empty?
      body = body.to_json

      response = basecamp_post(todolist_todos_url, body)
      response.status == 201 ? response : false
    end

    def todolist_todos_url
      bucket_url.join("todolists", todolist_id.to_s, "todos")
    end

    def fetch_projects
      response = basecamp_get(projects_url)
      [response.status, response.body.to_json]
    end

    def fetch_todo_lists
      response = basecamp_get(project_todolists_url)
      response.body.to_json
    end

    def fetch_project_members
      response = basecamp_get(project_members_url)
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
