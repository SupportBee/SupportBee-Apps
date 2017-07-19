module Bugify
  module ActionHandler
    def button
      ticket = payload.tickets.first
      response = create_issue(payload.overlay.title, payload.overlay.description)
      html = comment_html(response)
      comment_on_ticket(ticket, html)

      show_success_notification "Ticket sent to Bugify"
    end

    def projects
      [200, fetch_projects]
    end
  end
end

module Bugify
  require 'json'

  class Base < SupportBeeApp::Base
    string :url, :required => true, :label => 'Bugify url (eg https://bugify.me.com/)'
    string :api_key, :required => true, :label => 'Bugify API Key'

    def validate
      return false unless required_fields_present?

      begin
        test_api_request = http.get api_url('projects')
      rescue => e
        report_exception(e)

        show_error_notification "URL looks incorrect"
        return false
      end

      unless test_api_request.success?
        show_error_notification "URL or API Key Incorrect"
        return false
      end

      true
    end

    private

    def required_fields_present?
      are_required_fields_present = true

      if settings.url.blank?
        show_inline_error :url, "Please enter your Bugify url"
        are_required_fields_present = false
      end

      if settings.api_key.blank?
        show_inline_error :api_key, "Please enter your Bugify API Key"
        are_required_fields_present = false
      end

      return are_required_fields_present
    end

    def fetch_projects
      response = bugify_get(api_url('projects'))['projects'].to_json
    end

    def create_issue(subject, description)
      response = http_post api_url('issues') do |req|
        req.body = URI.encode_www_form(:project => project_id,:subject => subject,:description => description.gsub('\n', '<br/>'))
      end
    end

    def bugify_get(url)
      response = http.get "#{url.to_s}"
      response.body
    end

    def project_id
      payload.overlay.projects_select
    end

    def api_url(resource="")
      "#{settings.url}/api/#{resource}.json?api_key=#{settings.api_key}"
    end

    def comment_html(response)
      "<a href=#{settings.url}/issues/#{response.body['issue_id']}>Bugify issue #{response.body['issue_id']} created</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end
