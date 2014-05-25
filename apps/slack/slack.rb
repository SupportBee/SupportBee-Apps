module Slack

  module EventHandler

   def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      post_ticket(payload.ticket)
      true
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      post_agent_reply(payload.reply, payload.ticket)
      true
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      post_customer_reply(payload.reply, payload.ticket)
      true
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      post_comment(payload.comment, payload.ticket)
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

    string :webhook_url, :required => true, :label => 'Webhook URL'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => "Notify when a customer replied"
    boolean :notify_agent_reply_created, :default => true, :label => "Notify when an agent replies"
    boolean :notify_comment_created, :default => true, :label => "Notify when a comment is posted"
    boolean :post_content, :default => false, :label => "Post Full Content to Slack"

    white_list  :notify_ticket_created,
                :notify_agent_reply_created,
                :notify_customer_reply_created,
                :notify_comment_created,
                :post_content


  private

    def post_ticket(ticket)
      payload = {
      	:username => "SupportBee",
        :attachments => [
          		:fallback => "New Ticket from #{ticket.requester.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
        		:text => "New Ticket from #{ticket.requester.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
          		:color => "danger",
          		:fields => [
          			:title => "#{ticket.subject}",
          			:value => "#{ticket.content.text}"
          		]
          	]
      }.to_json
      post_to_slack(payload)
    end

    def post_agent_reply(reply, ticket)
      payload = {
      	:username => "SupportBee",
        :attachments => [
          		:fallback => "Agent Reply from #{reply.replier.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
        		:text => "Agent Reply from #{reply.replier.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
          		:color => "good",
          		:fields => [
          			:title => "Reply:",
          			:value => "#{reply.content.text}"
          		]
          	]
      }.to_json
      post_to_slack(payload)
    end

    def post_customer_reply(reply, ticket)
      text = "*Customer Reply* from #{reply.replier.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>"
      if settings.post_content.to_s == '1'
        text += "\n#{reply.content.text}"
      end
      post_to_slack(text)
    end

    def post_comment(comment, ticket)
      payload = {
      	:username => "SupportBee",
        :attachments => [
          		:fallback => "#{comment.commenter.name} commented on <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
        		:text => "#{comment.commenter.name} commented on <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
          		:color => "good",
          		:fields => [
          			:title => "Comment",
          			:value => "#{comment.content.text}"
          		]
          	]
      }.to_json
      post_to_slack(payload)
    end

    def post_to_slack(payload)
      response = http_post settings.webhook_url do |req|
      req.body = payload
    end
  end
  end
end

