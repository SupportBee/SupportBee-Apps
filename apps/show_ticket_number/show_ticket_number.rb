module ShowTicketNumber
  module EventHandler
    def ticket_created
      ticket = payload.ticket
      ticket.update(subject: "##{ticket.id} #{ticket.subject}")
    end
  end
end

module ShowTicketNumber
  class Base < SupportBeeApp::Base
  end
end

