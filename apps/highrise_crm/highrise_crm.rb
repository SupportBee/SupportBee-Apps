module HighriseCRM
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      puts "trying to find the person #{ticket.requester.email}"
      person = find_person(ticket.requester.email)
      puts "person #{person.inspect}"
      if person
        # Post info as a comment
        ticket.comment(:html => person_info_html(person))
      end
    end

    # Handle all events
    def all_events
      return true
    end
  end
end

module Highrise
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module HighriseCRM
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, :required => true, :hint => 'Highrise Auth Token'
    string :subdomain, :required => true, :label => 'Highrise Subdomain'
    # password :password, :required => true
    # boolean :notify_me, :default => true, :label => 'Notify Me'

    # White list settings for logging
    white_list :subdomain

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
    def find_person(email)
      setup_highrise
      people = Highrise::Person.search(:email => email)
      people.length > 0 ? people.first : nil
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
      html << "<a href='https://#{settings.subdomain}.highrisehq.com/people/#{person.id}'>View #{person.first_name}'s profile on Highrise</a>"
      html
    end
  end
end

