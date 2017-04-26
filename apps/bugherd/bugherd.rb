module Bugherd
  module ActionHandler
    def button
      http.basic_auth(settings.token, "")

      ticket = payload.tickets.first
      task = create_task(ticket, payload.overlay.description)
      if task['error']
        show_error_notification task['error'].capitalize!
        return
      end

      html = task_info_html(ticket, task)
      comment_on_ticket(ticket, html)

      show_success_notification "New Task created successfully in BugHerd"
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

    def validate
      return false unless required_fields_present?
      return false unless valid_api_token?
      true
    end

    private

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

    private

    def required_fields_present?
      are_required_fields_present = true
      if settings.api_token_blank?
        show_inline_error :token, "API Key cannot be blank"
        are_required_fields_present = false
      end
      if settings.project_id_blank?
        show_inline_error :project_id, "Project ID cannot be blank"
        are_required_fields_present = false
      end

      are_required_fields_present
    end

    def valid_api_token?
      http.basic_auth(settings.token, "x")
      response = http_get "https://www.bugherd.com/api_v2/projects/#{settings.project_id}.json"
      if response.status == 200
        true
      else
        show_error_notification "Invalid API Key and/or Project ID. Please verify the entered details"
        false
      end
    end

    def api_token_blank?
      settings.token.blank?
    end

    def project_id_blank?
      settings.project_id.blank?
    end
  end
end
