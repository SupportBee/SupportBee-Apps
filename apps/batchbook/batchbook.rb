module Batchbook
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      return true
    end

    # Handle all events
    def all_events
      return true
    end
  end
end

module Batchbook
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Batchbook
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, required: true, hint: 'Batchbook Auth Token'
    string :subdomain, required: true, label: 'Batchbook Subdomain'
    boolean :should_create_person, label: 'Create a New Person in Batchbook if one does not exist'
    boolean :return_ticket_content, label: 'Send ticket content to Batchbook'
  end
end
