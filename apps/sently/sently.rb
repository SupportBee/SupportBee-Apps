module Sently
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      ticket = payload.ticket
      send_sms("New ticket from #{ticket.requester.name || ticket.requester.email} - #{ticket.subject}")
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      reply = payload.reply
      send_sms("New customer reply from #{reply.replier.name || reply.replier.email} in #{payload.ticket.subject}")
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      reply = payload.reply
      send_sms("New agent reply from #{reply.replier.name || reply.replier.email} in #{payload.ticket.subject}")
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      comment = payload.comment
      send_sms("New comment from #{comment.commenter.name || comment.commenter.email} in #{payload.ticket.subject}")
    end
  end
end

module Sently
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Sent.ly Username', :hint => "Signup for a Sent.ly account at https://sent.ly/"
    password :password, :required => true, :label => 'Sent.ly Password', :hint => "Sent.ly password"
    string :number, :required => true, :label => 'Mobile no', :hint => "Mobile no with country code"
    boolean :notify_ticket_created, :default => true, :label => 'Sms when a Ticket is created'
    boolean :notify_agent_reply_created, :default => false, :label => 'Sms when an Agent replies'
    boolean :notify_customer_reply_created, :default => false, :label => 'Sms when a Customer replies'
    boolean :notify_comment_created, :default => false, :label => 'Sms when a Comment is created'

    white_list :notify_ticket_created

    def send_sms(message)
      http_post "http://sent.ly/command/sendsms" do |req|
        req.params[:username] = settings.username
        req.params[:password] = settings.password
        req.params[:to]       = "+#{settings.number}"
        req.params[:text]     = message[0...160]
      end
    end
  end
end
