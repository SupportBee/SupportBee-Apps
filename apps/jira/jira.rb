module Jira
  module ActionHandler
    def button
      begin
        return create_issue(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "JIRA Issue Created Successfully!"]
    end
  end
end

module Jira
  require 'json'

  class Base < SupportBeeApp::Base
    string :user_name, required: true, label: 'JIRA Username', hint: 'You have to use your JIRA username. The JIRA email address will not work. You can find the username in your JIRA Profile page'
    password :password, required: true, label: 'JIRA Password'
    string :domain, required: true, label: 'JIRA Domain', hint: 'JIRA OnDemand (Cloud), example: "https://example.atlassian.net". JIRA (Server), example: "http://yourhost:8080/jira"'

    def validate
      http.basic_auth(settings.user_name, settings.password)
      errors[:flash] = ["Cannot reach JIRA. Please check configuration"] unless test_ping.success?
      errors.empty? ? true : false
    end

    def project_key
      #payload.overlay.projects_select
      'TP'
    end

    private

    def test_ping
      jira_get(projects_url)
    end

    def jira_get(endpoint_url)
      http.basic_auth(settings.user_name, settings.password)

      response = http_get endpoint_url do |req|
        req.headers['Content-Type'] = 'application/json'
      end
      response
    end

    def jira_post(endpoint_url, body)
      http.basic_auth(settings.user_name, settings.password)

      response = http_post endpoint_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end
      binding.pry
      response
    end

    def create_issue(summary, description)
      body = {
        fields: {
          project: {
            key: project_key,
          },
          summary: summary,
          description: description,
          issuetype: {
            name: "Task"
          },
          labels: [
            "supportbee"
          ]
        }
      }
      jira_post(issues_url, body)
    end

    def projects_url
      "#{settings.domain}/rest/api/2/project"
    end
    
    def issues_url
      "#{settings.domain}/rest/api/2/issue"
    end
  end
end
