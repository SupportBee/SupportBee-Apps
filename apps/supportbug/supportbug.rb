module Supportbug 
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
  end
end

module Supportbug
  require 'json'

  class Base < SupportBeeApp::Base
    string :api_key, :required => true, :label => 'Bugify API Key'
    string :domain, :required => true, :label => 'Bugify domain'

    def validate
      errors[:flash] = ["Please fill in all the required fields"] if settings.api_key.blank? or settings.domain.blank?
      errors.empty? ? true : false
    end

    private

    def create_issue(subject, description)
      response = http_post "#{settings.domain}api" do |req|
        req.body = {:subject => subject, :description => description, :api_key => settings.api_key}.to_json
      end
    end

    def comment_html(response)
      "<a href=#{settings.domain}/issues/#{response.body['issue_id']}>Bugify issue #{response.body['issue_id']} created</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

  end
end
