module Pipedrive
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester
      http.basic_auth(settings.api_token, "")
      person = find_person(requester)
      if person
        update_note(person)
        #comment_on_ticket(person)
      else
        person = create_person(requester)
        update_note(person)
        #comment_on_ticket(person)
      end
      [200, "Ticket sent"]
    end
  end
end

module Pipedrive
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Pipedrive
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'Pipedrive Auth Token'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person'

    white_list :should_create_person

    def find_person(requester)
      first_name = split_name(requester)
      person = http_get('http://api.pipedrive.com/v1/persons/find') do |req|
        req.headers['Accept'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.params['term'] = 'goli'
      end 
 
      if person.body['data']
        return person.body['data'].first
      else 
        return nil
      end
    end
    
    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name = split_name(requester)
      puts first_name
      person = http_post('http://api.pipedrive.com/v1/persons') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.body = {name:first_name}.to_json
      end
      return person.body['data']
    end

    def split_name(requester)
      puts requester.name
      first_name, last_name = requester.name ? requester.name.split : [requester.email,'']
      return first_name
    end
   
    def update_note(person) 
      http_post('http://api.pipedrive.com/v1/notes') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.params['api_token'] = settings.api_token
      req.body = {person_id:person['id'],content:'hi'}.to_json
      end
    end

    def comment_on_ticket(html)
      ticket.comment(:html => html)
    end
 
    def existing_person_info(person)
      html = ""
      html << "<b> #{person['name']} </b><br/>" 
      html << "#{person['email']} " if person['email']
      html << "<br/>"
      html << person_link(person)
      html
    end

    def created_person_info(person)
      html = "Added <b> #{person['name']} </b> to Pipedrive... " 
      html << person_link(person)
      html
    end
    
    def person_link(person)
      "<a href='https://app.pipedrive.com/person/details/#{person['id']}'>View #{person['name']}'s profile on Pipedrive</a>"
    end

  end
end

