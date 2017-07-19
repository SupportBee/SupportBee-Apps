module Teamwork
  module ActionHandler
    def button
      ticket = payload.tickets.first
      html = ''
      result =
        case payload.overlay.type
        when 'todo_list'
          response = create_todo_list
          html = todolist_html_comment(response.headers['location']) if response and response.success?
          response
        when 'todo_item'
          response = create_todo_item
          html = todo_html_comment(response.headers['location']) if response and response.success?
          response
        end

      if response.success?
        show_success_notification "Ticket sent to Teamwork"
      else
        show_error_notification "Ticket not sent. Please check the settings of the app"
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
      if valid_api_token?
        return true
      else
        show_error_notification "The API Token doesn't look right"
        return false
      end
    end

    private

    def valid_api_token?
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

    def connection(url)
      conn = Faraday.new(:url => url)
      conn.basic_auth(settings.token, "any_password_will_do")
      conn
    end

    def teamwork_get(url)
      connection(url).get
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
      default_value_when_not_specifically_assigned = -1
      payload.overlay.assign_to == "none" ? default_value_when_not_specifically_assigned : payload.overlay.assign_to
    end

    def projects_url
      api_url("projects")
    end

    def project_url
      api_url("projects/#{project_id}")
    end

    def project_accesses_url
      api_url("projects/#{project_id}/people")
    end

    def project_messages_url
      project_url.join('messages')
    end

    def project_todolists_url
      api_url("projects/#{project_id}/todo_lists")
    end

    def todolist_todos_url
      api_url("tasklists/#{todolist_id}/tasks")
    end

    def teamwork_post(url, body)
      response = connection(url).post do |req|
        req.body = body
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
      end
    end

    def create_todo_list
      _description = description.blank? ? '' : description

      post_body = ({
        'todo-list' => {
          :name => title,
          :description => _description
        }
      }).to_json

      response = teamwork_post(project_todolists_url, post_body)
    end

    def create_todo_item
      post_body = {
        'todo-item' => {
          :content => title,
          :description => description,
          "responsible-party-id" => assignee_id
        }
      }.to_json

      response = teamwork_post(todolist_todos_url, post_body)
    end

    def fetch_projects
      response = teamwork_get(projects_url)
      ((JSON.parse response.body)['projects']).to_json
    end

    def fetch_todo_lists
      response = teamwork_get(project_todolists_url)
      ((JSON.parse response.body)['todo-lists']).to_json
    end

    def fetch_project_accesses
      response = teamwork_get(project_accesses_url)
      ((JSON.parse response.body)['people']).to_json
    end

    def todolist_html_comment(url)
      "Teamwork Task List created! - <a href='#{url}'>#{title}</a>"
    end

    def todo_html_comment(url)
      "Teamwork Task created! - <a href='#{url}'>#{title}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end
