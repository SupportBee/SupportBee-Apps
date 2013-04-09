module Jira
  module ActionHandler
    def button
      http.basic_auth(settings.user_name, settings.password)

      begin
        create_issue(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Ticket sent to Jira"]

    end
  end
end

module Jira
  class Base < SupportBeeApp::Base
    string :user_name, :required => true, :label => 'Enter User Name'
    string :password, :required => true, :label => 'Enter Password'
    string :account_name, :required => true, :label => 'Enter Account Name'
    string :project_key, :required => true, :label => 'Enter Project Key'
    string :issue_type, :required => true, :label => 'Enter Issue Type'

    private

    def create_issue(summary, description)
      response = http_post "https://#{settings.account_name}.atlassian.net/rest/api/2/issue" do |req|
	req.headers['Content-Type'] = 'application/json'
        req.body = {fields:{project:{key:settings.project_key}, summary:summary, description:description, issuetype:{name:settings.issue_type}}}.to_json
      end
    end
  end
end

