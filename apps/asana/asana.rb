module Asana
  module ActionHandler
    def button
      ticket = payload.tickets.first
      http.basic_auth(settings.token, "")
      begin
        response = create_task(payload.overlay.title, payload.overlay.notes)
        return [500, response.body['errors'].first['message']] if response.body['errors'] and not(response.body['errors'].empty?)
        comment_on_ticket ticket, comment_html(response)
      rescue Exception => e
        ErrorReporter.report(e)
        return [500, e.message]
      end

      [200, "Ticket sent to Asana"]

    end

    def projects
      [200, fetch_projects]
    end

    def orgs
      [200, fetch_orgs]
    end

    def workspace_users
      [200, fetch_workspace_users]
    end

  end
end

module Asana
  class WorkspaceNotFound < ::StandardError
    def message
      "Cannot find Workspace"
    end
  end

  class ProjectNotFound < ::StandardError
    def message
      "Cannot find Project"
    end
  end

  class Unauthorized < ::StandardError
    def message
      "Unauthorized. Please check if you have provided the right token in the app's settings page."
    end
  end

  class Base < SupportBeeApp::Base
    oauth  :asana, :required => true

    private


    def fetch_orgs
      response = asana_get(orgs_url)
      JSON.parse(response.body.to_json)['data'].to_json
    end

    def orgs_url
      api_url('workspaces')
    end

    def fetch_projects
      response = asana_get(projects_url(payload.overlay.org))
      JSON.parse(response.body.to_json)['data'].to_json
    end

    def fetch_workspace_users
      response = asana_get(users_url(payload.overlay.org))
      JSON.parse(response.body.to_json)['data'].to_json
    end

    def users_url(workspace)
      api_url("workspaces/#{workspace}/users")
    end

    def projects_url(workspace)
      api_url("workspaces/#{workspace}/projects")
    end

    def api_url(resource)
      "https://app.asana.com/api/1.0/#{resource}"
    end

    def asana_get(url)
      response = http.get url do |req|
       req.headers['Authorization'] = "Bearer #{settings.oauth_token}"
      end
    end

    def create_task(task_name, notes)
      response = http_post api_url('tasks') do |req|
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"
        req.headers['Content-Type'] = 'application/json'
        body = {:data => {:workspace => payload.overlay.org_select, :projects => payload.overlay.projects_select, :name => task_name, :notes => notes}}
        body[:data][:assignee] = payload.overlay.assign_to if payload.overlay.assign_to != "none"
        req.body = body.to_json
      end
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

    def comment_html(response)
      url = "https://app.asana.com/0/#{payload.overlay.projects_select}/#{response.body['data']['id']}"
      title = response.body['data']['name']
      "Asana task -  <a href='#{url}'>#{title}</a>"
    end

  end
end
