module Jira
  module ActionHandler
    def button
      http.basic_auth(settings.user_name, settings.password)

      begin
        return create_issue(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end
    end
  end
end

module Jira
  class Base < SupportBeeApp::Base
    string :user_name, :required => true, :label => 'Enter User Name', :hint => 'You have to use your JIRA username. The JIRA email address will not work. You can find the user name in your Profile page inside JIRA.'
    password :password, :required => true, :label => 'Enter Password'
    string :subdomain, :required => true, :label => 'Enter Subdomain', :hint => 'If your JIRA URL is "https://something.atlassian.net" then your Subdomain value is "something"'
    string :project_key, :required => true, :label => 'Enter Project Key', :hint => 'Your Project key can be found in the URL of the Project page'
    string :issue_type, :required => true, :label => 'Enter Issue Type', :hint => 'For example: "Bug". This field is case sensitive. "bug" will not work'

    private

    def create_issue(summary, description)
      response = http_post "https://#{settings.subdomain}.atlassian.net/rest/api/2/issue" do |req|
	      req.headers['Content-Type'] = 'application/json'
        req.body = {fields:{project:{key:settings.project_key}, summary:summary, description:description, issuetype:{name:settings.issue_type}}}.to_json
      end
      puts "#########{response.body}"
      if response.status == 201
        result = [200, "Ticket sent to JIRA"] if response.status == 201
      elsif response.status == 403
        result = [500, "Forbidden. Please check username/password"]
      else
        result = [500, "Error: #{response.body['errors'].first.last}"]
      end
      result
    end
  end
end

