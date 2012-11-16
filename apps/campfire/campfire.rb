module Campfire
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      notify_ticket(payload.ticket)
    end
  end
end

module Campfire
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Subdomain'
    string :token, :required => true, :label => 'Token'
    string :room, :required => true, :label => 'Room'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'

    white_list :subdomain, :room, :notify_ticket_created

    private 

    def notify_ticket(ticket, header = "New Ticket")
      campfire = Tinder::Campfire.new settings.subdomain, :token => settings.token
      room = campfire.find_room_by_name(settings.room)
      room.speak "[#{header}] #{ticket.subject} from #{ticket.requester.name} (https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id})"
    end
  end
end
