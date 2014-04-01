module Slack

  module EventHandler

   def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      post_ticket(payload.ticket)
      true
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      post_reply(payload.reply, payload.ticket)
      true
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      post_reply(payload.reply, payload.ticket)
      true
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'      
      post_comment(payload.comment)
      true      
    end    

  end

end

module Slack
  module ActionHandler

    def button     
     [200, "Success"]
    end

  end

end

module Slack

  require 'json'

  class Base < SupportBeeApp::Base
    
    string :token, :required => true, :hint => 'Slack API Token'
    string :channel, :required => true, :label => 'Channel Name'
    string :name, :required => true, :label => 'Publisher Name'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => "Notify when a customer replied"
    boolean :notify_agent_reply_created, :default => true, :label => "Notify when an agent replies"
    boolean :notify_comment_created, :default => true, :label => "Notify when a comment is posted"

    white_list :notify_ticket_created, :notify_agent_reply_created, :notify_customer_reply_created, :notify_comment_created


    private   

    def post_ticket(ticket)      
      post_to_slack(ticket.content.text)
    end

    def post_reply(reply,ticket)      
      text = "RE: #{ticket.subject} from #{reply.replier.name} (#{reply.replier.email})"
      text += reply.content.text
      post_to_slack(text)     
    end

    def post_comment(comment)
      text = comment.content.text
      post_to_slack(text)
    end

     def post_to_slack(text)
        payload = {"channel" => settings.channel,"username" => settings.name,"text" => text}.to_json
        response = http_post "https://supportbee.slack.com/services/hooks/incoming-webhook?token=#{settings.token}" do |req|
        req.body = payload
        end
    end    
  end
end

