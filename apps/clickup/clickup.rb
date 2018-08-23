module Clickup
  module ActionHandler
    def button
     ticket = payload.tickets.first
     overlay = payload.overlay

     name = overlay.title
     content = overlay.description
     priority = overlay.priority_select
     assignees = [overlay.assignee_select]

     response = create_task(name: name, content: content, priority: priority, assignees: assignees)
     task_id = response.body["id"]
     team_id = payload.overlay.team_select
     space_id = payload.overlay.space_select
     task_url = "https://app.clickup.com/#{team_id}/#{space_id}/t/#{task_id}"
     html = <<HTML
ClickUp Task Created!
<br />
<a href='#{task_url}'>#{ticket.subject}</a>
HTML
     ticket.comment(html: html)
     show_success_notification "Ticket sent to Clickup"
    end

    def teams
      [200, fetch_teams]
    end

    def spaces
      [200, fetch_spaces]
    end

    def projects
      [200, fetch_projects]
    end
  end
end

module Clickup
  class Base < SupportBeeApp::Base
    oauth :click_up

    private

    def token
      settings.oauth_token || settings.token
    end

    def team_id
      payload.overlay.team_id
    end

    def space_id
      payload.overlay.space_id
    end

    def list_id
      payload.overlay.list_select
    end

    def fetch_teams
      response = clickup_get(teams_url)
      response.body.to_json
    end

    def fetch_spaces
      response = clickup_get(spaces_url)
      response.body.to_json
    end

    def fetch_projects
      response = clickup_get(projects_url)
      response.body.to_json
    end

    def base_url
      Pathname.new("https://api.clickup.com/api/v1")
    end

    def projects_url
      base_url.join('space', space_id, 'project')
    end

    def spaces_url
      teams_url.join(team_id, 'space')
    end

    def teams_url
      base_url.join("team")
    end

    def tasks_url
      base_url.join("list", list_id, "task")
    end

    def create_task(data)
      http_post(tasks_url.to_s) do |req|
        req.body = data.to_json

        req.headers['Authorization'] = token
        req.headers['Content-Type'] = 'application/json'
      end
    end

    def clickup_get(url)
      http.get(url.to_s) do |req|
        req.headers['Authorization'] = token
        req.headers['Accept'] = 'application/json'
      end
    end
  end
end
