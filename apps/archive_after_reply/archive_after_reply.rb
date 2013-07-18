module ArchiveAfterReply
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      return true
    end

    # Handle all events
    def all_events
      ticket = payload.ticket
      begin
        archive_ticket(ticket) unless ticket.unanswered && ticket.archived == true
        unarchive_ticket(ticket) if ticket.unanswered 
      rescue Exception => e
        puts e.message
        puts e.backtrace
        return [500, e.message]
      end
    end
  end
end

module ArchiveAfterReply
  class Base < SupportBeeApp::Base

    private

    def archive_ticket(ticket)
      ticket.archive
    end

    def unarchive_ticket(ticket)
      ticket.unarchive
    end

  end
end
