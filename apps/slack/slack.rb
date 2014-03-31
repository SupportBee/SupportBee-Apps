module Slack

  module EventHandler

   def ticket_created
      post_ticket(payload.ticket)
      true
    end

    def agent_reply_created
      post_reply(payload.reply, payload.ticket)
      true
    end

    def customer_reply_created
      post_reply(payload.reply, payload.ticket)
      true
    end

  end

end

module Slack

  module ActionHandler

    def button     
     # Handle Action here
     [200, "Success"]
    end

  end

end

module Slack

  require 'json'

  class Base < SupportBeeApp::Base
    
    string :token, :required => true, :hint => 'Integration Token'
    string :channel, :required => true, :label => 'Channel to publish'
    string :name, :required => true, :label => 'Publisher Name'

    private   

    def post_ticket(ticket)      
      post_to_slack(ticket.content.text)
    end

    def post_reply(reply,ticket)      
      text = "RE: #{ticket.subject} from #{reply.replier.name} (#{reply.replier.email})"
      text += reply.content.text
      post_to_slack(text);     
    end

     def post_to_slack(text)
        payload = {"channel" => settings.channel,"username" => settings.name,"text" => text}.to_json
        response = http_post "https://supportbee.slack.com/services/hooks/incoming-webhook?token=#{settings.token}" do |req|
        req.body = payload
        end
    end    
  end
end

