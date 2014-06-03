module Batchbook
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, required: true, hint: 'Batchbook Auth Token'
    string :subdomain, required: true, label: 'Batchbook Subdomain'
    boolean :should_create_person, label: 'Create a new contact in Batchbook if one does not exist', default: true
    boolean :send_ticket_contents, label: 'Send the complete text of the ticket to Batchbook', hint: 'By default we only send a one line summary'

    include HTTParty

    def setup_batchbook
      self.class.base_uri("https://#{settings.subdomain}.batchbook.com")
    end

    def api_base_url
      "https://#{settings.subdomain}.batchbook.com/api/v1/"
    end

    def api_url(resource)
      "#{api_base_url}#{resource}.json?auth_token=#{settings.auth_token}"
    end

    def find_person(requester)
      options = { query: default_query_options.merge({ email: requester.email }) }
      response = http_get api_url('people') do |req|
        req.params[:email] = requester.email
      end
      response_json = response.body
      response_json['total'] > 0 ? response_json['people'].first : nil
    end

    def create_person(requester)
      first_name, last_name = requester.name ? requester.name.split : [requester.email, '']

      options = {
          person: {
            first_name: first_name,
            last_name: last_name,
            tags: [
              {name: 'SupportBee'}
            ],
            emails: [{
              address: requester.email,
              primary: true,
              label: 'work'
            }]
          }
      }
      response = http_post api_url('people') do |req|
        req.body = options
      end
      response.body['person']
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

    def create_communication(person)
      options = {
          communication: {
            title: payload.ticket.subject,
            body: communication_body,
            type: 'email',
            participants: [{
              type: 'from',
              contact_id: person['id'],
              contact_name: person_name(person)
            }]
          }
      }
      response = http_post api_url('communications') do |req|
        req.body = options
      end
      response.body['communication']
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

    def communication_body
      ticket = payload.ticket
      html = ""
      if settings.send_ticket_contents
        html << ticket.content.html + '<br />'
      else
        html << ticket.summary + '<br />'
        html << "<a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}</a>"
      end
    end
  end
end
