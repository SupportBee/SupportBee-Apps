module Batchbook
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      return if ticket.trash || ticket.spam
      requester = ticket.requester
      person = find_person(requester)
      if person
        ticket.comment(html: person_details_html(person))
      elsif settings.should_create_person?
        person = create_person(requester)
        puts "person #{person}"
        ticket.comment(html: new_person_details_html(person))
      else
        return true
      end

      create_communication(person)
      true
    end
  end
end
