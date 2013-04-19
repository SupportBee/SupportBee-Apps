module PushOver
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      push_ticket(payload.ticket)
      return true
    end

    def customer_reply_created
      return true unless settings.send_customer_replies.to_s == '1'
      push_customer_reply(payload.reply, payload.ticket)
    end

    def agent_reply_created
      return true unless settings.send_agent_replies.to_s == '1'
      push_agent_reply(payload.reply, payload.ticket)
    end
  end
end

module PushOver
  class Base < SupportBeeApp::Base
    # Settings
    string :user_key, :required => true, :label => 'User Key from PushOver', :hint => 'Get your User Key by signing up at http://www.pushover.net/'
    boolean :send_customer_replies, :default => false, :label => 'Notify replies from Customers?'
    boolean :send_agent_replies, :default => false, :label => 'Notify replies from Agents?'


    def push_ticket(ticket)
      http_post "https://api.pushover.net/1/messages.json" do |req|
        req.params[:token] = OMNIAUTH_CONFIG['push_over']['apikey']
        req.params[:user] = settings.user_key
        req.params[:title] =  "#{ticket.subject} from #{ticket.requester.name} (#{ticket.requester.email})"
        req.params[:message] = ticket.content.text[0..512] #512 Limitation from PushOver API
        req.params[:url] = "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
      end
    end

    def push_customer_reply(reply, ticket)
      http_post "https://api.pushover.net/1/messages.json" do |req|
        req.params[:token] = OMNIAUTH_CONFIG['push_over']['apikey']
        req.params[:user] = settings.user_key
        req.params[:title] =  "RE: #{ticket.subject} from Customer #{reply.replier.name} (#{reply.replier.email})"
        req.params[:message] = ticket.content.text[0..512]
        req.params[:url] = "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
      end
    end

    def push_agent_reply(reply, ticket)
      http_post "https://api.pushover.net/1/messages.json" do |req|
        req.params[:token] = OMNIAUTH_CONFIG['push_over']['apikey']
        req.params[:user] = settings.user_key
        req.params[:title] =  "RE: #{ticket.subject} from Agent #{reply.replier.name} (#{reply.replier.email})"
        req.params[:message] = ticket.content.text[0..10000]
        req.params[:url] = "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
      end
    end
  end
end

