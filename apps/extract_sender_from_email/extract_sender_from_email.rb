module ExtractSenderFromEmail
  module EventHandler
    def ticket_created
      if has_email_in_body?
        new_email = get_email_from_body
        ticket.change_sender(new_email)
        comment_that_sender_has_changed(new_email)
      end
    end
  end
end

module ExtractSenderFromEmail
  class Base < SupportBeeApp::Base
    private

    def has_email_in_body?
      not get_email_from_body.nil?
    end

    def comment_that_sender_has_changed(new_email)
      html = "<p>Ticket's sender changed to #{new_email}</p>"
      ticket.comment(html: html)
    end

    def get_email_from_body
      email_regex = /\b[A-Z0-9._%+-]+@([A-Z0-9.-]+\.)+[A-Z]{2,4}\b/i
      matches = ticket.content.text.match(email_regex)
      matches && matches[0]
    end

    def ticket
      payload.ticket
    end
  end
end
