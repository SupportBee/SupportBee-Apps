module Campfire
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      notify_ticket(payload.ticket)
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      notify_reply(payload.ticket, payload.reply, "New Customer Reply")
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      notify_reply(payload.ticket, payload.reply)
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      notify_comment(payload.ticket, payload.comment)
    end
  end
end

module Campfire
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Subdomain'
    string :token, :required => true, :label => 'Token'
    string :room, :required => true, :label => 'Room'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when a Ticket is created'
    boolean :notify_agent_reply_created, :default => false, :label => 'Notify when an Agent replies'
    boolean :notify_customer_reply_created, :default => false, :label => 'Notify when a Customer replies'
    boolean :notify_comment_created, :default => false, :label => 'Notify when a Comment is created'

    white_list :subdomain, :room, :notify_ticket_created

    private 

    def with_rescue
      begin
        yield
      rescue
        return false
      end
      true
    end

    def notify_ticket(ticket, header = "New Ticket")
      with_rescue do
        setup_campfire
        @room.speak "[#{header}] #{ticket.subject} from #{ticket.requester.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      end
    end

    def notify_reply(ticket, reply, header = "New Agent Reply")
      with_rescue do
        setup_campfire
        @room.speak "[#{header}] for #{ticket.subject} from #{reply.replier.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      end
    end

    def notify_comment(ticket, comment, header = "New Comment") 
      with_rescue do
        setup_campfire
        @room.speak "[#{header}] for #{ticket.subject} from #{comment.commenter.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      end
    end

    def setup_campfire
      @campfire = Tinder::Campfire.new settings.subdomain, :token => settings.token
      @room = @campfire.find_room_by_name(settings.room)
    end
  end
end
