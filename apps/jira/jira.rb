module Jira
  module ActionHandler
    def button
      http.basic_auth(settings.user_name, settings.password)

      begin
        result = create_issue(payload.overlay.title, payload.overlay.description)
        if result
          return [200, "Ticket sent to JIRA"]
        else
          return [500, "Ticket not sent. Please check the settings of the app"]
        end
      rescue Exception => e
        return [500, e.message]
      end
    end
  end
end

module Jira
  class Base < SupportBeeApp::Base
    string :user_name, :required => true, :label => 'Enter User Name'
    string :password, :required => true, :label => 'Enter Password'
    string :subdomain, :required => true, :label => 'Enter Subdomain'
    string :project_key, :required => true, :label => 'Enter Project Key'
    string :issue_type, :required => true, :label => 'Enter Issue Type'

    private

    def create_issue(summary, description)
      response = http_post "https://#{settings.subdomain}.atlassian.net/rest/api/2/issue" do |req|
	      req.headers['Content-Type'] = 'application/json'
        req.body = {fields:{project:{key:settings.project_key}, summary:summary, description:description, issuetype:{name:settings.issue_type}}}.to_json
      end
      response.status == 201 ? true : false
    end
  end
end

