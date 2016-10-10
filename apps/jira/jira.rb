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

    def validate
      if settings.user_name.blank? or settings.password.blank? or settings.domain.blank?
        errors[:flash] = "Please fill in all required details" 
      else
      errors[:flash] = ["We could not reach JIRA. Please check the configuration, and try again"] unless test_ping.success?
      end
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

    def jira_put(endpoint_url, body)
      basic_auth
      response = http_put endpoint_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
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
      body = build_request_body(summary, description)
      jira_post(issues_url, body)
    end

    def assign_issue(issue)
      body = {name: assignee_name}
      jira_put(assign_issue_url(issue['id']), body)
    end

    def build_request_body(summary, description)
      body = {
        fields: {
          project: {
            key: project_key,
          },
          summary: summary,
          description: description,
          issuetype: {
            id: issue_type
          }
        }
      }

      if assigned?
        body[:fields][:assignee] = { name: assignee_name }
      end

      body
    end

    def assigned?
      assignee_name != "none"
    end

    def fetch_projects
      response = jira_get(projects_url)
      response.body["projects"].to_json
    end

    def fetch_assignable_users
      basic_auth
      response = http_get (users_url + "?project=#{project_key}") do |req|
        req.headers['Content-Type'] = 'application/json'
      end
      response.body.to_json
    end

    def fetch_issue_types
      response = jira_get(projects_url)
      projects = response.body["projects"]
      project = (projects.detect {|project|  project["key"] == project_key})
      project["issuetypes"].to_json
    end


    def users_url
      "#{domain}/rest/api/2/user/assignable/search"
    end

    def projects_url
      "#{domain}/rest/api/2/issue/createmeta"
    end
    
    def issues_url
      "#{domain}/rest/api/2/issue"
    end
    
    def assign_issue_url(issue_id)
      "#{domain}/rest/api/2/issue/#{issue_id}/assignee"
    end

    def create_issue_html(issue, summary)
      "JIRA Issue Created! \n <a href=#{domain}/browse/#{issue['key']}>#{issue['key']}: #{summary}</a>"
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
