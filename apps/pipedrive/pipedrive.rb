module Pipedrive
  module EventHandler
    def ticket_created
      ticket = payload.ticket
      return if ticket.trash || ticket.spam
      requester = ticket.requester

      begin
        person = find_person(requester)
        html = ''

        if person
          html = existing_person_info(person)
        else
          person = create_person(requester)
          html = created_person_info(person) if person
        end

        if person
          update_note(person, ticket)
          comment_on_ticket(html, ticket)
        end
      rescue Exception => e
        context = ticket.context.merge(company_subdomain: payload.company.subdomain, app_slug: self.class.slug, payload: payload)
        ErrorReporter.report(e, context: context)
        [500, e.message]
      end
      [200, "Ticket sent"]
    end
  end
end

module Pipedrive
  class Base < SupportBeeApp::Base
    string  :api_token, :required => true, :label => 'Pipedrive Auth Token'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person in Pipedrive if one does not exist'
    boolean :send_ticket_content, :required => false, :label => 'Send Ticket\'s Full Contents to Pipedrive', :default => false

    def api_url(endpoint)
      "https://api.pipedrive.com/v1#{endpoint}"
    end

    white_list :should_create_person

    def validate
      return false unless required_fields_present?
      return false unless valid_credentials?
      true
    end

    def find_person(requester)
      response = http_get api_url('/persons/find') do |req|
        req.headers['Accept'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.params['term'] = requester.email
      end
      body = response.body['data']
      body ? body.first : nil
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      person = http_post api_url('/persons') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.body = {name:name(requester), email:[requester.email]}.to_json
      end
      return person.body['data']
    end

    def name(requester)
      requester.name || requester.email
    end

    def update_note(person, ticket)
      http_post api_url('/notes') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.body = {person_id:person['id'],content:generate_note_content(ticket)}.to_json
      end
    end

    def comment_on_ticket(html, ticket)
      ticket.comment(:html => html)
    end

    def existing_person_info(person)
      html = ""
      html << "<b> #{person['name']} </b><br/>"
      html << "<br/>"
      html << person_link(person)
      html
    end

    def created_person_info(person)
      html = "Added <b> #{person['name']} </b> to Pipedrive...<br/> "
      html << person_link(person)
      html
    end

    def person_link(person)
      "<a href='https://app.pipedrive.com/person/details/#{person['id']}'>View #{person['name']}'s profile on Pipedrive</a>"
    end

    def generate_note_content(ticket)
      note = "<a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
      note << "<br/> #{ticket.content.text}" if settings.send_ticket_content.to_s == '1'
      note
    end

    private

    def required_fields_present?
      if settings.api_token.blank?
        errors[:flash] = "API Token cannot be blank"
      end
      errors.empty? ? true : false
    end

    def valid_credentials?
      response = http_get api_url('/activityTypes') do |req|
        req.headers['Accept'] = 'application/json'
        req.params['api_token'] = settings.api_token
      end
      if response.success?
        true
      else
        errors[:flash] = "Invalid API Token. Please verify the entered details"
        false
      end
    end

  end
end
