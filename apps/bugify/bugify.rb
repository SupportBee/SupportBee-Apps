module Bugify 
  module ActionHandler
    def button
      ticket = payload.tickets.first
      begin
        response = create_issue(payload.overlay.title, payload.overlay.description)
        html = comment_html(response)
        comment_on_ticket(ticket, html)
      rescue Exception => e
        return [500, e.message]
      end
      [200, "Ticket sent to Bugify"]
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
      begin
        if settings.api_key.blank? or settings.url.blank?
          errors[:flash] = ["Please fill in all the required fields"]
        elsif not(test_ping.success?)
          errors[:flash] = ["URL or API Key Incorrect"] unless test_ping.success?
        end
        errors.empty? ? true : false
      rescue Exception => e
        errors[:flash] = [e.message]
        errors[:url] = ["URL looks incorrect"]
        false
      end
    end

    private

    def test_ping
      response = http.get api_url('projects')
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
