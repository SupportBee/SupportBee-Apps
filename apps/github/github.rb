module Github 
  module ActionHandler
    def button

      begin
        create_issue(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Ticket sent to Github Issues"]

    end
  end
end

module Github
  require 'json'

  class Base < SupportBeeApp::Base
    string :owner, :required => true, :label => 'Owner'
    string :repo, :required => true, :label => 'Repository'
    string :token, :required => true, :label => 'Token', :hint => 'You can get the API Token following the instructions here - https://help.github.com/articles/creating-an-oauth-token-for-command-line-use'

    private

    def create_issue(issue_title, description)
      response = http_post "https://api.github.com/repos/#{settings.owner}/#{settings.repo}/issues?access_token=#{settings.token}" do |req|
        req.body = {:title => issue_title, :body => description}.to_json
      end
    end

  end
end
