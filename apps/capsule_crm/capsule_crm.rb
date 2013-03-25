module CapsuleCrm
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
	  ticket = payload.ticket
	  requester = ticket.requester
	  http.basic_auth(settings.api_token, "")
          person = find_person(requester)  
          unless person
            person =  create_new_person(requester)
            html = new_person_info_html(person)
            #comment_in_ticket(html)
	  else
	    html = person_info_html(person)
            send_note(person)
            #comment_in_ticket(html)
	  end
	  [200, "Ticket sent to Capsulecrm"]
    end
  end
end

module CapsuleCrm
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module CapsuleCrm
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'Capsule Auth Token'
    string :account_name, :required => true, :label => 'Capsule Account Name'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person'
	
    white_list :account_name, :should_create_person

    def find_person(requester)
      first_name = split_name(requester)
      response = http_get('https://supportbee.capsulecrm.com/api/party') do |req|
        req.headers['Accept'] = 'application/json'
      end
      people = response.body['parties']['person']
      if response.body['parties']==first_name
        person =  people.select{|pe| pe['firstName'] == 'first_name'}.first
      end
      return nil
    end
 
    def create_new_person(requester)
      location = create_person(requester)
      note_to_new_person(location)
      person = get_person(location)
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name = split_name(requester)
      puts first_name
      response = http_post('https://supportbee.capsulecrm.com/api/person') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {person:{firstName:first_name}}.to_json
      end
      location = response['location']
    end

    def send_note(person)
      person_id = person['id']
      http_post('https://supportbee.capsulecrm.com/api/party/#{person_id}/history') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {historyItem:{note:'Hello from SupportBee!!!'}}.to_json
      end
      return
    end
    
    def note_to_new_person(location)
      http_post "#{location}/history" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {historyItem:{note:'Hello from SupportBee!!!'}}.to_json
      end
    end

    def split_name(requester)
      puts requester.name
      first_name, last_name = requester.name ? requester.name.split : [requester.email,'']
      return first_name
    end

    def get_person(location)
      response = http_get "#{location}" do |req|
        req.headers['Accept'] = 'application/json'
        end
      person = response.body['person']
    end
      
    def person_info_html(person)
      html = ""
      html << "<br/>"
      html << "#{person['firstName']}"
      html << "#{person['contact']} " if person['contact']
      html << "<br/>"
      html << person_link(person)
      html
    end

    def new_person_info_html(person)
      html = "Added #{person['firstName']} to Capsule - "
      html << person_link(person)
      html
    end

    def person_link(person)
      "<a href='https://#{settings.account_name}.capsulecrm.com/party/#{person['id']}'>View #{person['firstName']}'s profile on capsule</a>"
    end
   
    def comment_in_ticket(html)
      ticket.comment(:html => html)
    end
     

  end
 end
