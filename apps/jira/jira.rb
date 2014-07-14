module Jira
  module ActionHandler
    def button
      ticket = payload.tickets.first

      issue = create_issue(payload.overlay.title, payload.overlay.description)
      return [500, "Error: #{issue.body["errors"].to_s}"] if issue.status == 400
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
  
    def issue_types
      [200, fetch_issue_types]
    end
  end
end

module Jira
  require 'json'

  class Base < SupportBeeApp::Base
    string :user_name, required: true, label: 'JIRA Username', hint: 'You have to use your JIRA username. The JIRA email address will not work. You can find the username in your JIRA Profile page'
    password :password, required: true, label: 'JIRA Password'
    string :domain, required: true, label: 'JIRA Domain', hint: 'JIRA OnDemand (Cloud), example: "https://example.atlassian.net". JIRA (Server), example: "http://yourhost:8080/jira"'
    string :subdomain, label: 'JIRA subdomain', hint: 'Ignore this if you have filled in the JIRA Domain Name, this is only to support previous integrations'

    def validate
      errors[:flash] = ["Cannot reach JIRA. Please check configuration"] unless test_ping.success?
      errors.empty? ? true : false
    end

    def project_key
      payload.overlay.projects_select
    end

    def assignee_name
      payload.overlay.users_select
    end

    def issue_type
      payload.overlay.issue_type_select
    end

    private

    def test_ping
      jira_get(projects_url)
    end

    def jira_get(endpoint_url)
      basic_auth

      response = http_get endpoint_url do |req|
        req.headers['Content-Type'] = 'application/json'
      end
      response
    end

    def jira_post(endpoint_url, body)
      basic_auth

      response = http_post endpoint_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end
      response
    end

    def create_issue(summary, description)
      body = assigned_body(summary, description) if assigned?
      body = unassigned_body(summary, description) unless assigned?

      jira_post(issues_url, body)
    end

    def unassigned_body(summary, description)
      { fields: {
          project: {
            key: project_key,
          },
          summary: summary,
          description: description,
          issuetype: {
            id: issue_type
          },
          labels: [
            "supportbee"
          ]
        }
      }
    end

    def assigned_body(summary, description)
      { fields: {
          project: {
            key: project_key,
          },
          summary: summary,
          description: description,
          issuetype: {
            id: issue_type
          },
          assignee: {
            name: assignee_name
          },
          labels: [
            "supportbee"
          ]
        }
      }
    end

    def assigned?
      assignee_name != "none"
    end

    def fetch_projects
      response = jira_get(projects_url)
      response.body.to_json
    end

    def fetch_assignable_users
      basic_auth
      response = http_get (users_url + "?project=#{project_key}") do |req|
        req.headers['Content-Type'] = 'application/json'
      end
      flash[:errors] = ["It seems you do not have access to Assign Issues."] if response.status == 401
      response.body.to_json
    end

    def fetch_issue_types
      response = jira_get(issue_type_url)
      response.body.to_json
    end

    def issue_type_url
      "#{domain}/rest/api/2/issuetype"
    end

    def users_url
      "#{domain}/rest/api/2/user/assignable/search"
    end

    def projects_url
      "#{domain}/rest/api/2/project"
    end
    
    def issues_url
      "#{domain}/rest/api/2/issue"
    end

    def create_issue_html(issue, subject)
      "JIRA Issue Created! \n <a href=#{issue['self']}>#{subject}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(html: html)
    end

    def basic_auth
      http.basic_auth(settings.user_name, settings.password)
    end

    def domain
      return settings.domain unless settings.domain.blank?
      return "https://#{settings.subdomain}.atlassian.net"
    end
  end
end
