module Campfire
  module EventHandler
    def ticket_created
      puts "##########{settings.inspect}"
      return unless settings.notify_ticket_created == 1
      #notify_ticket(payload.ticket)
    end
  end

  module ActionHandler
    def button
      return [200, ''] unless payload.tickets
      payload.tickets.each do |ticket|
        notify_ticket(ticket)
      end
    end
  end
end

module Campfire
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Subdomain'
    string :token, :required => true, :label => 'Token'
    string :room, :required => true, :label => 'Room'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'

    private 

    def notify_ticket(ticket)
      campfire = Tinder::Campfire.new settings.subdomain, :token => settings.token
      room = campfire.find_room_by_name(settings.room)
      room.speak "New Ticket: #{ticket.subject}"
    end
  end
end
