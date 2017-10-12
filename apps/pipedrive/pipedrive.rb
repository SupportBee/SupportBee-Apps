module Pipedrive
  module EventHandler
    def ticket_created
      ticket = payload.ticket
      return if ticket.spam_or_trash?

      requester = ticket.requester
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
    end
  end
end

module Pipedrive
  class Base < SupportBeeApp::Base
    string  :api_token, :required => true, :label => 'Pipedrive Auth Token'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person in Pipedrive if one does not exist'
    boolean :send_ticket_content, :required => false, :label => 'Send Ticket\'s Full Contents to Pipedrive', :default => false

    white_list :should_create_person

    def validate
      if settings.api_token.blank?
        show_inline_error :api_token, "Please enter your Pipedrive API Token"
        return false
      end

      unless test_api_request.success?
        show_error_notification "Invalid API Token. Please verify the entered details"
        return false
      end

      true
    end

    private

    def test_api_request
      response = http_get api_url('/activityTypes') do |req|
        req.headers['Accept'] = 'application/json'
        req.params['api_token'] = settings.api_token
      end
      response
    end

    def api_url(endpoint)
      "https://api.pipedrive.com/v1#{endpoint}"
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

      if settings.send_ticket_content.to_s == '1'
        note << "<br/> #{ticket.content.text}"

        unless ticket.content.attachments.blank?
          note << "<br/><br/><strong>Attachments</strong><br/>"
          ticket.content.attachments.each do |attachment|
            note << "<a href='#{attachment.url.original}'>#{attachment.filename}</a>"
            note << "<br/>"
          end
        end
      end

      note
    end
  end
end
