module Jira
  module ActionHandler
    def button
      ticket = payload.tickets.first
      issue = create_issue(payload.overlay.title, payload.overlay.description)
      return [500, "There was an error creating an Issue in JIRA. Please try again"] unless issue
      html = create_issue_html(issue.body, ticket.subject)

      comment_on_ticket(ticket, html)
      [200, "JIRA Issue Created Successfully!"]
    end

    def projects
      [200, fetch_projects]
    end

    def users
      [200, fetch_assignable_users]
    end
  end
end

module Jira
  require 'json'

  class Base < SupportBeeApp::Base
    string :user_name, required: true, label: 'JIRA Username', hint: 'You have to use your JIRA username. The JIRA email address will not work. You can find the username in your JIRA Profile page'
    password :password, required: true, label: 'JIRA Password'
    string :domain, required: true, label: 'JIRA Domain', hint: 'JIRA OnDemand (Cloud), example: "https://example.atlassian.net". JIRA (Server), example: "http://yourhost:8080/jira"'
    string :subdomain, label: 'JIRA subdomain', hint: 'Ignore this if you have filled in the JIRA Domain Name'

    def validate
      http.basic_auth(settings.user_name, settings.password)
      errors[:flash] = ["Cannot reach JIRA. Please check configuration"] unless test_ping.success?
      errors.empty? ? true : false
    end

    def project_key
      payload.overlay.projects_select
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

    def fetch_projects
      response = jira_get(projects_url)
      response.body.to_json
    end

    def fetch_assignable_users
      http.basic_auth(settings.user_name, settings.password)

      response = http_get users_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          projectKeys: [
            project_key
          ]
        }.to_json
      end
      binding.pry
      response.body.to_json
    end

    def users_url
      "#{settings.domain}/rest/api/2/user/assignable/multiProjectSearch"
    end

    def projects_url
      "#{settings.domain}/rest/api/2/project"
    end
    
    def issues_url
      "#{settings.domain}/rest/api/2/issue"
    end

    def create_issue_html(issue, subject)
      "JIRA Issue Created! \n <a href=#{issue['self']}>#{subject}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(html: html)
    end
  end
end
