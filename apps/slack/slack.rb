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
    string :url_webhook, :required => true, :label => 'Webhook URL', :hint => "If you configure this, you can ignore the rest of the settings."
    string :token, :hint => 'Slack Incoming Webhook Token'
    string :channel, :label => 'Channel Name', :hint => "If #example is the Channel you want to send messages to, then enter 'example'"
    string :domain, :label => 'Company Name in Domain', :hint => 'If your base URL is "http://example.slack.com", then enter "example"'

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

    def validate
      errors[:flash] = ["Please fill in either the Webhook URL or other required settings"] if validate_presense_of_url
      errors.empty? ? true : false
    end

    def validate
      errors[:flash] = ["Webhook URL or other settings incorrect"] unless test_ping.success?
      errors.empty? ? true : false
    end

    private

    def validate_presense_of_url
      not(settings.url_webhook.blank?) or not(settings.token.blank? and settings.channel.blank? and settings.domain.blank?)
    end

    def test_ping
      if settings.url_webhook.blank?
        response = http_post create_webhook_url do |req|
          body = {
            :channel => "##{settings.channel}",
            :username => "SupportBee",
            :text => "Hello, World!"
          }
          req.body = body.to_json
        end
      else
        response = http_post settings.url_webhook do |req|
          body = {
            username: "SupportBee",
            text: "Hello, World!"
          }
          req.body = body.to_json
        end
      end
      response
    end

    def post_ticket(ticket)
      if settings.post_content.to_s == '1'
        payload = {
          :username => "SupportBee",
          :attachments => [
                :fallback => "New Ticket from #{ticket.requester.name}: <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
                :text => "New Ticket from #{ticket.requester.name}: <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
                :color => "danger",
                :fields => [
                  :title => "#{ticket.subject}",
                  :value => "#{ticket.content.text}"
                ]
              ]
        }
      else
        payload = {
          :username => "SupportBee",
          :text => "*New Ticket* from *#{ticket.requester.name}*: <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>"
        }
      end
      post_to_slack(payload)
    end

    def post_agent_reply(reply, ticket)
      if settings.post_content.to_s == '1'
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
        }
      else
        payload = {
          :username => "SupportBee",
          :text => "*Agent Reply* from *#{reply.replier.name}* in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>"
        }
      end
      post_to_slack(payload)
    end

    def post_customer_reply(reply, ticket)
      if settings.post_content.to_s == '1'
	      payload = {
	      	:username => "SupportBee",
	        :attachments => [
	          		:fallback => "Customer Reply from #{reply.replier.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
                :text => "Customer Reply from #{reply.replier.name} in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>",
	          		:color => "danger",
	          		:fields => [
	          			:title => "Reply:",
	          			:value => "#{reply.content.text}"
	          		]
	          	]
	      }
	  else
	  	payload = {
          :username => "SupportBee",
          :text => "*Customer Reply* from *#{reply.replier.name}* in <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>"
        }
      end
      post_to_slack(payload)
    end

    def post_comment(comment, ticket)
   	  if settings.post_content.to_s == '1'
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
	      }
  	  else
  	  	payload = {
          :username => "SupportBee",
          :text => "*#{comment.commenter.name}* commented on <https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}>"
        }
  	  end
      post_to_slack(payload)
    end

    def post_to_slack(payload)
      if settings.url_webhook.blank?
        text = payload[:attachments][0][:text] + "\n" + payload[:attachments][0][:fields][0][:value] unless payload[:attachments].blank?
        text = payload[:text] unless payload[:text].blank?

        body = {
          "channel" => "##{settings.channel}",
          "username" => "SupportBee",
          "text" => text 
        }

        response = http_post create_webhook_url do |req|
          req.body = body.to_json
        end
      else
        response = http_post settings.url_webhook do |req|
          req.body = payload.to_json
        end
      end
    end

    def create_webhook_url
      "https://#{settings.domain}.slack.com/services/hooks/incoming-webhook?token=#{settings.token}"
    end
  end
end

