module HighriseCRM
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester
      setup_highrise
      person = find_person(requester)
      if person
        puts "posting a comment"
        ticket.comment(:html => person_info_html(person))
      else
        puts "creating a person"
        if person = create_person(requester)
          ticket.comment(:html => new_person_info_html(person))
        end
      end

      if person
        puts "creating a note"
        # Create a note in highrise
        note = Highrise::Note.new(:subject_id => person.id, :subject_type => 'Person', :body => "[New Ticket] <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>")
        note.save
        puts note.errors.inspect
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

    # White list settings for logging
    white_list :subdomain, :should_create_person

    def find_person(requester)
      people = Highrise::Person.search(:email => requester.email)
      people.length > 0 ? people.first : nil
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name, last_name = requester.name.split
      person = Highrise::Person.new(:contact_data => {:email => requester.email},
                                    :first_name => first_name,
                                    :last_name => last_name) 
      if person.save
        return person
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

    def person_link(person)
      "<a href='https://#{settings.subdomain}.highrisehq.com/people/#{person.id}'>View #{person.first_name}'s profile on Highrise</a>"
    end
  end
end

