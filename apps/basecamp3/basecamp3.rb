module Basecamp3
  module ActionHandler
    def button
      ticket = payload.tickets.first
      html = ''
      response =
        case payload.overlay.type
        when 'message'
          response = create_message
          html = message_html_comment(response.body) if response and response.body
          response
        when 'todo_list'
          response = create_todo_list
          html = todolist_html_comment(response.body) if response and response.body
          response
        when 'todo_item'
          response = create_todo_item
          html = todo_html_comment(response.body) if response and response.body
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

    string :account_id,
      required: true,
      label: 'Enter Account ID',
      hint: 'If your basecamp URL is "https://3.basecamp.com/9999999/" enter "9999999"'

    def validate
      begin
        response = basecamp_get(projects_url)
      rescue => e
        ErrorReporter.report(e)
        show_error_notification("Failed to fetch projects from your basecamp. Please try again after sometime or contact support at support@supportbee.com")
        return false
      end

      return true if response.status == 200

      e = StandardError.new("Failed to fetch projects from your basecamp. Please try again after sometime or contact support at support@supportbee.com")
      context = {
        response_status: response.status,
        response_body: response.body
      }
      ErrorReporter.report(e, context: context)
      show_error_notification(response.body)
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

    def assignee_ids
      Array(payload.overlay.assign_to) rescue []
    end

    def base_url
      Pathname.new("https://3.basecampapi.com").join(settings.account_id.to_s)
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

    def basecamp_post(path, body, params={})
      http.post build_url(path, params) do |req|
        req.headers['Authorization'] = 'Bearer ' + token
        req.headers['User-Agent'] = "SupportBee Developers (nisanth@supportbee.com)"
        req.headers['Content-Type'] = 'application/json'
        req.body = body
      end
    end

    def basecamp_get(path, params={})
      http.get build_url(path, params) do |req|
       req.headers['Authorization'] = 'Bearer ' + token
       req.headers['User-Agent'] = "SupportBee Developers (nisanth@supportbee.com)"
       req.headers['Accept'] = 'application/json'
      end
    end

    def fetch_paginated_data(path)
      Enumerator.new do |yielder|
        page = 1

        loop do
          response = basecamp_get(path, page: page)
          results = response.body

          if response.success? && not(results.blank?)
            results.map { |item| yielder << item }
            page += 1
          else
            raise StopIteration
          end
        end
      end.lazy
    end

    def build_url(path, params={})
      query_params = params.map { |key, value| "#{key}=#{value}" }.join("&") unless params.blank?
      url = "#{path.to_s}.json"
      url = url + "?#{query_params}" if query_params

      url
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
      projects = fetch_paginated_data(projects_url)
      [200, projects.to_json]
    end

    def fetch_todo_lists
      response = basecamp_get(project_todolists_url)
      response.body.to_json
    end

    def fetch_project_members
      response = basecamp_get(project_members_url)
      response.body.to_json
    end

    def message_html_comment(message_hash)
      <<-COMMENT_HTML
Basecamp message created!
<br>
<a href="#{message_hash['app_url']}">#{message_hash['subject']}</a>
COMMENT_HTML
    end

    def todolist_html_comment(todolist_hash)
      <<-COMMENT_HTML
Basecamp To-do List created!
<br>
<a href="#{todolist_hash['app_url']}">#{todolist_hash['name']}</a>
COMMENT_HTML
    end

    def todo_html_comment(todo_hash)
      <<-COMMENT_HTML
Basecamp todo created in the list <a href="#{todo_hash['app_url']}">#{todo_hash['content']}</a>
COMMENT_HTML
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end
