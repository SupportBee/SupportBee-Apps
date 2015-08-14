module Moxtra
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

module Moxtra
  module ActionHandler
    def button
     [200, "Success"]
    end
  end
end

module Moxtra
  require 'json'

  class Base < SupportBeeApp::Base
    string :url_webhook, :required => true, :label => 'Webhook URL', :hint => "Paste the Moxtra Webhook URL here."

    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => "Notify when a customer replied"
    boolean :notify_agent_reply_created, :default => true, :label => "Notify when an agent replies"
    boolean :notify_comment_created, :default => true, :label => "Notify when a comment is posted"
    boolean :post_content, :default => false, :label => "Post Full Content to Moxtra"

    white_list  :notify_ticket_created,
                :notify_agent_reply_created,
                :notify_customer_reply_created,
                :notify_comment_created,
                :post_content

    def validate
      errors[:flash] = ["Please fill in the Webhook URL"] if validate_presense_of_url
      errors.empty? ? true : false
    end

    def validate
      errors[:flash] = ["Webhook URL is incorrect"] unless test_ping.success?
      errors.empty? ? true : false
    end

    private

    def validate_presense_of_url
      not(settings.url_webhook.blank?)
    end

    def test_ping
        response = http_post url_webhook do |req|
          body = {
            :username => "SupportBee",
            :text => "Hello, World!"
          }
          req.body = body.to_json
        end
      response
    end

    def post_ticket(ticket)
      if settings.post_content.to_s == '1'
        payload = {
          :username => "SupportBee",
          :attachments => [
                :ticketid => "#{ticket.id}",
                :user => "#{ticket.requester.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "#{ticket.subject}",
                  :value => "#{ticket.content.text}"
                ]
              ]
        }
      else
      payload = {
          :username => "SupportBee",
          :attachments => [
          :ticketid => "#{ticket.id}",
          :user => "#{ticket.requester.name}: ",
          :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
          :fields => [
          :title => "#{ticket.subject}",
          :value => ""
          ]
          ]
      }
      end
      post_to_moxtra(payload)
    end

    def post_agent_reply(reply, ticket)
      if settings.post_content.to_s == '1'
        payload = {
            :username => "SupportBee",
            :attachments => [
                :ticketid => "#{ticket.id}",
                :ticketsubject => "#{ticket.subject}",
                :replier => "#{reply.replier.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "Reply:",
                  :value => "#{reply.content.text}"
                ]
              ]
        }
      else
        payload = {
            :username => "SupportBee",
            :attachments => [
                :ticketid => "#{ticket.id}",
                :ticketsubject => "#{ticket.subject}",
                :replier => "#{reply.replier.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "Reply:",
                  :value => ""
                ]
              ]
        }
      end
      post_to_moxtra(payload)
    end

    def post_customer_reply(reply, ticket)
      if settings.post_content.to_s == '1'
	      payload = {
	      	:username => "SupportBee",
            :attachments => [
                :ticketid => "#{ticket.id}",
                :ticketsubject => "#{ticket.subject}",
                :replier => "#{reply.replier.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "Reply:",
                  :value => "{reply.content.text}"
                ]
              ]
	      }
	  else
	  	payload = {
          	:username => "SupportBee",
            :attachments => [
                :ticketid => "#{ticket.id}",
                :ticketsubject => "#{ticket.subject}",
                :replier => "#{reply.replier.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "Reply:",
                  :value => ""
                ]
              ]
        }
      end
      post_to_moxtra(payload)
    end

    def post_comment(comment, ticket)
   	  if settings.post_content.to_s == '1'
	      payload = {
          	:username => "SupportBee",
            :attachments => [
                :ticketid => "#{ticket.id}",
                :ticketsubject => "#{ticket.subject}",
                :commenter => "#{comment.commenter.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "Comment:",
                  :value => "#{comment.content.text}"
                ]
              ]
	      }
  	  else
  	  	payload = {
          	:username => "SupportBee",
        	:attachments => [
                :ticketid => "#{ticket.id}",
                :ticketsubject => "#{ticket.subject}",
                :commenter => "#{comment.commenter.name}: ",
                :url => "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}|#{ticket.subject}",
                :fields => [
                  :title => "Comment:",
                  :value => ""
                ]
              ]
        }
  	  end
      post_to_moxtra(payload)
    end

    def post_to_moxtra(payload)
        response = http_post settings.url_webhook do |req|
          req.body = payload.to_json
        end
    end

  end
end

