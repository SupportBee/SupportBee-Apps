module CapsuleCrm
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      return if ticket.spam_or_trash?
      requester = ticket.requester
      http.basic_auth(settings.api_token, "")

      person = find_person(requester)
      if person
        html = person_info_html(person)
        send_note(ticket, person)
      else
        if settings.should_create_person.to_s == '1'
          person =  create_new_person(ticket, requester)
          html = new_person_info_html(person)
        else
          return
        end
      end

      comment_on_ticket(ticket, html)
      show_success_notification "Ticket sent to Capsule"
    end
  end
end

module CapsuleCrm
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'Capsule Auth Token', :hint => 'Login to your Capsule account, go to My Preferences (in the User Menu) > API Authentication Token'
    string :subdomain, :required => true, :hint => 'If your Capsule Crm URL is "https://example.capsulecrm.com" then your Subdomain name is "example"'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person in Capsule if one does not exist'
    boolean :return_ticket_content, :required => false, :label => 'Send Ticket Content to Capsule (by default the Ticket Summary is sent)'

    white_list :should_create_person, :subdomain

    def validate
      return false unless required_fields_present?
      return false unless valid_credentials?
      true
    end

    private

    def find_person(requester)
      first_name = split_name(requester)
      response = http_get "https://#{settings.subdomain}.capsulecrm.com/api/party" do |req|
        req.headers['Accept'] = 'application/json'
        req.params['email'] = requester.email
      end
      body = response.body if response.status == 200
      person = body['parties']['person'] if body
      person ? person : nil
    end

    def create_new_person(ticket, requester)
      location = create_person(requester)
      note_to_new_person(location, ticket)
      get_person(location)
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name = split_name(requester)
      response = http_post "https://#{settings.subdomain}.capsulecrm.com/api/person" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {person:{firstName:first_name, contacts:{email:{emailAddress:requester.email}}}}.to_json
      end
      location = response['location']
    end

    def send_note(ticket, person)
      person_id = person['id']
      http_post "https://#{settings.subdomain}.capsulecrm.com/api/party/#{person_id}/history" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {historyItem:{note:generate_note_content(ticket)}}.to_json
      end
    end

    def note_to_new_person(location, ticket)
      http_post "#{location}/history" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {historyItem:{note:generate_note_content(ticket)}}.to_json
      end
    end

    def split_name(requester)
      first_name, last_name = requester.name ? requester.name.split(' ') : [requester.email,'']
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
      html << "<b> #{person['firstName']} </b><br/>"
      html << "#{person['title']} " if person['title']
      html << "<br/>"
      html << person_link(person)
      html
    end

    def new_person_info_html(person)
      html = "Added #{person['firstName']} to Capsule...<br/> "
      html << person_link(person)
      html
    end

    def person_link(person)
      "<a href='https://#{settings.subdomain}.capsulecrm.com/party/#{person['id']}'>View #{person['firstName']}'s profile on capsule</a>"
    end

    def comment_on_ticket(ticket, html)
        ticket.comment(:html => html)
    end

    def generate_note_content(ticket)
      note = ""
      settings.return_ticket_content.to_s == '1' ? note << ticket.content.text : note << ticket.summary
      note << "\n" + "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

    def required_fields_present?
      are_required_fields_present = true

      if settings.api_token.blank?
        are_required_fields_present = false
        show_inline_error :api_token, "API Token cannot be blank"
      end

      if settings.subdomain.blank?
        are_required_fields_present = false
        show_inline_error :subdomain, "Subdomain cannot be blank"
      end

      return are_required_fields_present
    end

    def valid_credentials?
      http.basic_auth(settings.api_token, "x")
      response = http_get "https://#{settings.subdomain}.capsulecrm.com/api/users" do |req|
        req.headers['Accept'] = 'application/json'
      end

      if response.status == 200
        true
      else
        show_error_notification "Invalid subdomain and/or API Token. Please verify the entered details"
        false
      end
    end
  end
end
