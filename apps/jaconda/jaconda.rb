module Jaconda
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      ticket = payload.ticket
      notify_jaconda "<b>New Ticket</b> from #{ticket.requester.name}: <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      notify_jaconda "<b>Agent Reply</b> from #{reply.replier.name} in <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      notify_jaconda "<b>Customer Reply</b> from #{reply.replier.name} in <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      ticket = payload.ticket
      comment = payload.comment
      notify_jaconda "<b>Comment</b> from #{comment.commenter.name} on <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end
  end
end

module Jaconda
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Subdomain'
    string :room, :required => true, :label => 'Room ID'
    string :token, :required => true, :label => 'Room Token', :hint => "This is the room token and not the user token"
    boolean :notify_ticket_created, :default => true, :label => 'Notify when a Ticket is created'
    boolean :notify_agent_reply_created, :default => true, :label => 'Notify when an Agent replies'
    boolean :notify_customer_reply_created, :default => true, :label => 'Notify when a Customer replies'
    boolean :notify_comment_created, :default => true, :label => 'Notify when a Comment is created'

    white_list :subdomain, :room, :notify_ticket_created, :notify_comment_created, :notify_customer_reply_created, :notify_agent_reply_created
    
    def with_rescue
      begin
        yield
      rescue
        return false
      end
      true
    end

    def setup_jaconda
      Jaconda::Notification.authenticate(:subdomain => settings.subdomain,
                                         :room_id => settings.room,
                                         :room_token => settings.token)
    end

    def notify_jaconda(message)
      with_rescue do
        setup_jaconda
        Jaconda::Notification.notify(:text => message, :sender_name => "SupportBee")
      end
    end
  end
end
