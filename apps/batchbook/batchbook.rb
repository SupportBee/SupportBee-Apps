module Batchbook
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      setup_batchbook

      ticket = payload.ticket
      requester = ticket.requester
      person = find_person(requester)
      if person
        ticket.comment(html: person_details_html(person))
      elsif settings.should_create_person?
        person = create_person(requester)
        ticket.comment(html: new_person_details_html(person))
      end

      true
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

    def person_details_html(person)
      html = "<b>#{person_name(person)}</b><br />"
      html << "Phone: #{number}<br />" if number = person_number(person)
      html << "Address: #{address}<br />" if address = person_address(person)
      html << person_link_html(person)
    end

    def new_person_details_html(person)
      html = "Added <b>#{person_name(person)}</b> to Batchbook - "
      html << person_link_html(person)
    end

    def default_query_options
      { auth_token: settings.auth_token }
    end

    def person_name(person)
      "#{person['first_name']} #{person['last_name']}".strip
    end

    def person_number(person)
      return unless phone = person['phones'].first
      phone['number']
    end

    def person_address(person)
      return unless address = person['addresses'].first
      keys = %w(address_1 address_2 city state postal_code country)
      keys.each_with_object('') do |k, addr|
        return addr unless address['k']
        "#{addr}, #{address['k']}"
      end
    end

    def person_link_html(person)
      "<a href='https://#{settings.subdomain}.batchbook.com/contacts/#{person['id']}'>View #{person['first_name']}'s profile on Batchbook</a>"
    end
  end
end
