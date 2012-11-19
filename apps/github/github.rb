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
  class Base < SupportBeeApp::Base
    string :owner, :required => true, :label => 'Owner'
    string :repo, :required => true, :label => 'Repository'
    string :token, :required => true, :label => 'Token'

    private

    def create_issue(issue_title, description)
      response = http_post "https://api.github.com/repos/#{settings.owner}/#{settings.repo}/issues?access_token=#{settings.token}" do |req|
        req.body = "{ \"title\": \"#{issue_title}\", \"body\": \"#{description.gsub(/\r?\n/, '<br>')}\"}"
      end
    end

  end
end

