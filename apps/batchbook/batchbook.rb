module Batchbook
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      setup_batchbook
      ticket = payload.ticket
      person = find_person(ticket.requester)
      true
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

    include HTTParty

    def setup_batchbook
      self.class.base_uri("https://#{settings.subdomain}.batchbook.com")
    end

    def find_person(requester)
      options = { query: default_query_options.merge({ email: requester.email }) }
      response = self.class.get('/api/v1/people.json', options)
      response.parsed_response['people'].first
    end

    def default_query_options
      { auth_token: settings.auth_token }
    end
  end
end
