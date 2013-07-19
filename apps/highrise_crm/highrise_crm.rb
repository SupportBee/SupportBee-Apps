module HighriseCRM
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester
      setup_highrise
      person = find_person(requester)
      if person
        ticket.comment(:html => person_info_html(person))
      else
        if person = create_person(requester)
          ticket.comment(:html => new_person_info_html(person))
        end
      end

      if person
        # Create a note in highrise
        note = Highrise::Note.new(:subject_id => person.id, :subject_type => 'Person', :body => generate_note_content(ticket))
        note.save
      end
      return true
    end

  end
end

module HighriseCRM
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, :required => true, :hint => 'Highrise Auth Token'
    string :subdomain, :required => true, :label => 'Highrise Subdomain'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person in Highrise if one does not exist'
    boolean :return_ticket_content, :required => false, :label => 'Send ticket content to Highrise'

    # White list settings for logging
    white_list :subdomain, :should_create_person

    def find_person(requester)
      people = Highrise::Person.search(:email => requester.email)
      people.length > 0 ? people.first : nil
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name, last_name = requester.name ? requester.name.split : [requester.email,'']
      person = Highrise::Person.new(:first_name => first_name,
                                    :last_name => last_name,
                                    :contact_data => {
                                      :email_addresses => [
                                        :email_address => {:address => requester.email}
                                      ]
                                    })
      if person.save
        return person
      else
        # Cannot do anything
      end
      return nil
    end

    def setup_highrise
      Highrise::Base.site = "https://#{settings.subdomain}.highrisehq.com"
      Highrise::Base.user = settings.auth_token
      Highrise::Base.format = :xml
    end

    def person_info_html(person)
      html = ""
      html << "<b> #{person.name} </b><br/>" 
      html << "#{person.title} " if person.title
      html << "#{person.company_name}" if person.company_name
      html << "<br/>"
      html << person_link(person)
      html
    end

    def new_person_info_html(person)
      html = "Added <b> #{person.name} </b> to Highrise - " 
      html << person_link(person)
      html
    end

    def generate_note_content(ticket)
      note = ""
      note << ticket.summary + "<br/>" if settings.return_ticket_content.to_s == '1'
      note << "<a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}</a>"
    end

    def person_link(person)
      "<a href='https://#{settings.subdomain}.highrisehq.com/people/#{person.id}'>View #{person.first_name}'s profile on Highrise</a>"
    end
  end
end

