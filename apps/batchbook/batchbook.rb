module Batchbook
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      setup_batchbook

      requester = payload.ticket.requester
      person = find_person(requester)
      return true if person || !settings.should_create_person?

      create_person(requester)
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

    def create_person(requester)
      first_name, last_name = requester.name ? requester.name.split : [requester.email, '']

      options = {
        query: default_query_options.merge({
          person: {
            first_name: first_name,
            last_name: last_name,
            emails: [{
              address: requester.email,
              primary: true,
              label: 'work'
            }]
          }
        })
      }
      response = self.class.post('/api/v1/people.json', options)
      response.parsed_response['person']
    end

    def default_query_options
      { auth_token: settings.auth_token }
    end
  end
end
