module CapsuleCrmV2
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      return if ticket.spam_or_trash?

      requester = ticket.requester

      person = find_person(requester)
      if person
        html = person_info_html(person)
        send_note(ticket, person)
      else
        if settings.should_create_person.to_s == '1'
          person = create_new_person(ticket, requester)
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

module CapsuleCrmV2
  class Base < SupportBeeApp::Base
    oauth :capsule,
      required: true,
      oauth_options: {
        scope: "read write"
      }

    boolean :should_create_person,
      default: true,
      required: false,
      label: 'Create a New Person in Capsule if one does not exist'
    boolean :return_ticket_content,
      required: false,
      label: 'Send Ticket Content to Capsule (by default the Ticket Summary is sent)'

    white_list :should_create_person

    def validate
      response = nil

      begin
        response = capsule_get(users_url)
      rescue => e
        ErrorReporter.report(e)
        show_error_notification "Validation failed for you Capsule account. Please try again after sometime or contact support at support@supportbee.com"
      end

      return true if response.status == 200

      e = StandardError.new("Failed to fetch Capsule Users")
      context = {
        response_status: response.status,
        response_body: response.body
      }
      ErrorReporter.report(e, context: context)
      show_error_notification response.body
      return false
    end

    private

    def find_person(requester)
      response = http.get api_url("/parties") do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"

        req.params['email'] = requester.email
      end

      return nil unless response.status == 200
      if response.body['parties']['person'].is_a?(Array)
        response.body['parties']['person'].first
      else
        response.body['parties']['person']
      end
    end

    def create_new_person(ticket, requester)
      location = create_person(requester)
      note_to_new_person(location, ticket)
      get_person(location)
    end

    def create_person(requester)
      first_name = split_name(requester)
      response = http.post api_url("/parties") do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"
        req.body = {
          party: {
            firstName: first_name,
            emailAddresses: [
              {
                type: "Work",
                address: requester.email
              }
            ]
          }
        }.to_json
      end

      location = response['location']
    end

    def send_note(ticket, person)
      person_id = person['id']

      http_post api_url("/parties/#{person_id}/history") do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"
        req.body = {historyItem:{note:generate_note_content(ticket)}}.to_json
      end
    end

    def note_to_new_person(location, ticket)
      http_post "#{location}/history" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"

        req.body = {historyItem:{note:generate_note_content(ticket)}}.to_json
      end
    end

    def split_name(requester)
      first_name, last_name = requester.name ? requester.name.split(' ') : [requester.email, '']
      return first_name
    end

    def get_person(location)
      response = http.get "#{location}" do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"
      end

      response.body['party']
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
      "<a href='#{site_url}/party/#{person['id']}'>View #{person['firstName']}'s profile on capsule</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(html: html)
    end

    def generate_note_content(ticket)
      note = ""
      note << (settings.return_ticket_content.to_s == '1' ? ticket.content.text : ticket.summary)
      note << "\n" + "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

    def site_url
      @site ||= get_site
      @site["site"]["url"]
    end

    def get_site
      response = capsule_get(site_url)
      JSON.parse(response.body)
    end

    def capsule_get(path, params = {})
      http.get api_url(path) do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}" 
      end
    end

    def site_url
      base_url.join("site")
    end

    def users_url
      base_url.join("users")
    end

    def base_url
      Pathname.new("https://api.capsulecrm.com/api/v2")
    end
  end
end
