module Campfire
  module EventHandler
    def ticket_created
      campfire = Tinder::Campfire.new settings.subdomain, :token => settings.token
      room = campfire.find_room_by_name(settings.room)
      room.speak "New Ticket: #{payload.ticket.subject}"
    end
  end
end

module Campfire
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Subdomain'
    string :token, :required => true, :label => 'Token'
    string :room, :required => true, :label => 'Room'
  end
end
