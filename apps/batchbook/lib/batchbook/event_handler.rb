module Batchbook
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      setup_batchbook

      ticket = payload.ticket
      requester = ticket.requester
      person = find_person(requester)
      if person
        ticket.comment(html: person_details_html(person))
      elsif settings.should_create_person?
        person = create_person(requester)
        ticket.comment(html: new_person_details_html(person))
      else
        return true
      end

      create_communication(person) if settings.return_ticket_content?
      true
    end
  end
end
