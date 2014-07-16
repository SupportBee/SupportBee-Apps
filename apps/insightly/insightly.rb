module Insightly
  module ActionHandler
    def button
     ticket = payload.tickets.first
     begin
       response = create_task(payload.overlay.title, payload.overlay.description)
       html = comment_html(response)
       comment_on_ticket(ticket, html)
     rescue Exception => e
        return [500, e.message]
     end
     [200, "Insightly Task Created!"]
    end

    def projects
      [200, fetch_projects]
    end

  end
end

module Insightly
  require 'base64'
  require 'json'

  class Base < SupportBeeApp::Base

    string  :api_key,
            required: true,
            label: 'Insightly API Key',
            hint: 'Can be found in User Settings page.'

    def validate
      errors[:flash] = ["Please fill in all the required fields"] if settings.url.blank? or settings.api_key.blank?
      errors.empty? ? true : false
    end

    def validate
      errors[:flash] = ["API Key Invalid"] unless test_ping.success?
      errors.empty? ? true : false
    end
    
    def project_id
      payload.overlay.projects_select
    end

    private

    def test_ping
      insightly_get(api_url('projects'))
    end

    def create_task(title, description)
      post_body = {
        title: title,
        details: description,
        project_id: project_id,
        completed: false,
        publicly_visible: true,
        responsible_user_id: '535114',
        owner_user_id: '535114'
      }.to_json
      response = http.post api_url('tasks') do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Content-Type'] = 'application/json'
        req.body = post_body
      end
    end

    def insightly_get(url)
      response = http.get url do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Accept'] = 'application/json'
      end
    end

    def fetch_projects
      response = insightly_get(api_url('projects'))
      response.body.to_json
    end

    def api_url(resource="")
      "https://api.insight.ly/v2.1/#{resource}"
    end

    def comment_html(response)
      "Insightly Task created!\n <a href=/TaskDetails/#{response.body['TASK_ID']}>#{response.body['Title']}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end

