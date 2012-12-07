module Hipchat
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      ticket = payload.ticket
      send_to_hipchat "#{ticket.subject} from #{ticket.requester.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      paste_in_hipchat ticket.summary
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      send_to_hipchat "[Agent Reply]: On #{ticket.subject} from #{reply.replier.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      paste_in_hipchat reply.content.text
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      send_to_hipchat "[Customer Reply]: On #{ticket.subject} from #{reply.replier.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      paste_in_hipchat reply.content.text
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      ticket = payload.ticket
      comment = payload.comment
      send_to_hipchat "[Comment]: On #{ticket.subject} from #{comment.commenter.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
      paste_in_hipchat comment.content.text
    end
  end
end

module Hipchat
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'API Token'
    string :room, :required => true, :label => 'Room (Name)'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => "Notify when a customer replied"
    boolean :notify_agent_reply_created, :default => true, :label => "Notify when an agent replies"
    boolean :notify_comment_created, :default => true, :label => "Notify when a comment is posted"

    white_list :subdomain, :room, :notify_ticket_created, :notify_agent_reply_created, :notify_customer_reply_created, :notify_comment_created

    private 

    def send_to_hipchat(message)
      get_room.send('SupportBee', message)
    end

    def paste_in_hipchat(text)
      get_room.send('SupportBee', text.slice(0,140), :message_format => 'text')
    end

    def get_room
      @client ||= HipChat::Client.new(settings.token)
      @client[settings.room]
    end
  end
end
