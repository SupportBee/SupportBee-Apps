module Capsule
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
	  ticket = payload.ticket
	  requester = ticket.requester
	  setup_capsule
	  if check = create_person
	    puts "New Account Created"
          end
	  [200, "Ticket sent to Capsulecrm"]
    end
  end
end

module Capsule
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Capsule
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'Capsule Auth Token'
    string :account_name, :required => true, :label => 'Capsule Account Name'
    string :new_person, :required => false, :label => 'New Person', :hint => 'Enter name with surname'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person'
	
    white_list :account_name, :should_create_person


    def create_person
      return unless settings.should_create_person.to_s == '1'
      puts "hello"
      first_name, last_name = settings.new_person ? settings.new_person.split : settings.new_person.split
      puts "hello1"
     # begin
        response = http_get "https://#{settings.account_name}.capsulecrm.com/api/party" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.params['first_name'] = first_name
        req.params['last_name'] = last_name
        puts "hell2"
        end 
        begin
           person = response.body['data']
        rescue Exception => e
          puts e.message
          puts e.backtrace
        end
        return person
    #  rescue Exception => e
      #  puts e.message
      #  puts e.backtrace
     # end
    end

    def setup_capsule
      http_post "https://#{settings.account_name}.capsulecrm.com/api/users" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.params['api_token'] = settings.api_token
      end
    end

  end
 end
