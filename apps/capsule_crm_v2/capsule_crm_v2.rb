module CapsuleCrmV2
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      return if ticket.spam_or_trash?

      requester = ticket.requester
      comment_content = nil

      if person = find_person(requester)
        comment_content = person_info_html(person)
        send_note(person, ticket)
      else
        return unless settings.should_create_person.to_s == '1'

        person = create_new_person(ticket, requester)
        comment_content = new_person_info_html(person)
      end

      comment_on_ticket(ticket, comment_content)
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
      response = capsule_get(parties_url.join("search"), q: requester.email)
      return nil unless response.status == 200

      person = Hashie::Mash.new(response.body['parties'].first)
      person.blank? ? nil : person
    end

    def create_new_person(ticket, requester)
      person = create_person(requester)
      send_note(person, ticket)

      person
    end

    def create_person(requester)
      first_name, last_name = split_name(requester)
      body = {
        party: {
          type: "person",
          firstName: first_name,
          lastName: last_name,
          emailAddresses: [
            {
              type: "Work",
              address: requester.email
            }
          ]
        }
      }

      response = capsule_post(parties_url, body)
      Hashie::Mash.new(response.body['party'])
    end

    def send_note(person, ticket)
      body = {
        entry: {
          party: {
            id: person.id
          },
          type: "note",
          content: generate_note_content(ticket)
        }
      }

      capsule_post(entries_url, body)
    end

    def split_name(requester)
      first_name, last_name = requester.name ? requester.name.split(' ') : [requester.email, '']
      [first_name, last_name]
    end

    def get_person(location)
      capsule_get(location).body['party']
    end

    def person_info_html(person)
      html = "<strong>#{person.firstName} #{person.lastName}</strong> is already a contact in Capsule"
      html << "<br />"
      html << person.title if person.title
      html << "<br />"
      html << person_link(person)
      html
    end

    def new_person_info_html(person)
      html = "Added <strong>#{person.firstName} #{person.lastName}</strong> to Capsule"
      html << "<br />"
      html << person_link(person)
      html
    end

    def person_link(person)
      "<a href='#{capsule_account_url}/party/#{person.id}'>View #{person.firstName}'s profile on Capsule</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(html: html)
    end

    def generate_note_content(ticket)
      note = ""
      note << (settings.return_ticket_content.to_s == '1' ? ticket.content.text : ticket.summary)
      note << "\n" + "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

    def capsule_account_url
      @site ||= get_site
      @site["site"]["url"]
    end

    def get_site
      capsule_get(site_url).body
    end

    def capsule_post(url, body, params = {})
      http.post url.to_s do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"

        req.body = body.to_json
      end
    end

    def capsule_get(url, params = {})
      http.get url.to_s do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{settings.oauth_token}"

        unless params.blank?
          params.each do |key, value|
            req.params[key] = value
          end
        end
      end
    end

    def entries_url
      base_url.join("entries")
    end

    def parties_url
      base_url.join("parties")
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
