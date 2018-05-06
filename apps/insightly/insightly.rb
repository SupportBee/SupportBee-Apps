module Insightly
  module EventHandler
    def ticket_created
      return unless settings.sync_contacts.to_s == '1'

      ticket = payload.ticket
      return if ticket.trash || ticket.spam
      requester = ticket.requester

      contact = find_contact(requester)
      html = ''

      if contact
        html = existing_contact_info(contact)
      else
        contact = create_contact(requester)
        html = created_contact_info(contact)
      end

      if contact
        update_note(ticket) if settings.send_ticket_content.to_s == "1"
        ticket.comment(html: html)
      end
    end
  end

  module ActionHandler
    def button
     ticket = payload.tickets.first
     task = create_task(payload.overlay.title, payload.overlay.description, ticket.requester)
     note = create_note(payload.overlay.title, payload.overlay.description, ticket.requester)
     html = task_created_html(task)
     ticket.comment(:html => html)

     show_success_notification "Insightly Task Created!"
    end

    def projects
      [200, fetch_projects]
    end

    def opportunities
      [200, fetch_opportunities]
    end

    def users
      [200, fetch_users]
    end
  end
end

module Insightly
  require 'base64'
  require 'json'

  class Base < SupportBeeApp::Base
    string  :api_key,
            required: true,
            label: 'Insightly API Key',
            hint: 'Can be found in User Settings page.'
    string  :subdomain,
            required: true,
            label: 'Insightly Subdomain',
            hint: 'Say https:/example.insight.ly is your Insightly domain, enter "example"'
    string :tagged_name,
            label: 'Tag Name',
            hint: 'The tag name will be used to identify new Insightly contacts created from within SupportBee. If unspecified, default tag name used would be "supportbee". The tagging happens only if the tag new contacts checkbox below is ticked.'
    boolean :tag_contacts,
            label: 'Tag new contacts that are created from within SupportBee with a tag name',
            default: false
    boolean :sync_contacts,
            label: 'Create Insightly Contact with Customer Information',
            default: true
    boolean :send_ticket_content,
            label: "Automatically add ticket's full content as a note to Insightly Contact",
            hint: "This would only work if 'Create Insightly Contact with Customer Information' is checked",
            default: false

    def validate
      return false unless required_fields_present?

      unless test_api_request.success?
        show_error_notification "API Key Invalid"
        return false
      end

      return true
    end

    private

    def project_id
      return nil if payload.overlay.projects_select == 'none'
      payload.overlay.projects_select
    end

    def opportunity_id
      return nil if payload.overlay.opportunities_select == 'none'
      payload.overlay.opportunities_select
    end

    def responsible_user_id
      payload.overlay.responsible_select
    end

    def owner_user_id
      payload.overlay.owner_select
    end

    def status
      payload.overlay.status_select
    end

    def priority
      payload.overlay.priority_select.to_i
    end

    def required_fields_present?
      are_required_fields_present = true

      if settings.subdomain.blank?
        are_required_fields_present = false
        show_inline_error :subdomain, "Please enter your Insightly Subdomain"
      end

      if settings.api_key.blank?
        are_required_fields_present = false
        show_inline_error :subdomain, "Please enter your Insightly API Key"
      end

      return are_required_fields_present
    end

    def test_api_request
      insightly_get(api_url('projects'))
    end

    def create_task(title, description, requester)
      tasklinks = []
      request_body = {
        title: title,
        details: description,
        completed: false,
        publicly_visible: true,
        responsible_user_id: responsible_user_id,
        owner_user_id: owner_user_id,
        status: status,
        priority: priority
      }
      if project_id
        request_body[:project_id] = project_id
        tasklinks << { project_id: project_id }
      end
      if opportunity_id
        request_body[:opportunity_id] = opportunity_id
        tasklinks << { opportunity_id: opportunity_id }
      end
      if contact = find_or_create_contact(requester)
        tasklinks << { contact_id: contact['CONTACT_ID'] }
      end
      request_body[:tasklinks] = tasklinks

      response = api_post('tasks', request_body)
      if response.status == 201
        return response.body
      else
        raise StandardError.new("Failed to create an Insightly task. Here's the response from Insightly: #{response.body}")
      end
    end

    def create_note(title, description, requester)
      contact = find_or_create_contact(requester)
      body = {
        title: title,
        body: description,
        link_subject_type: 'CONTACT',
        link_subject_id: contact["CONTACT_ID"],
      }

      response = api_post('notes', body)

      if response.status == 201
        return response.body
      else
        raise StandardError.new("Failed to create an Insightly note. Here's the response from Insightly: #{response.body}")
      end
    end

    def update_note(ticket)
      create_note(ticket.subject, generate_note_content(ticket), ticket.requester)
    end

    def find_or_create_contact(requester)
      ret = find_contact(requester)
      return ret unless ret.nil?
      create_contact(requester)
    end

    def create_contact(requester)
      name = requester.name.split(' ', 2)
      body = {
        first_name: name[0],
        last_name: name[1],
        contactinfos: [{
          type: 'Email',
          detail: requester.email
        }]
      }

      body[:tags] = [{tag_name: get_tag_name}] if settings.tag_contacts.to_s == "1"
      response = api_post('Contacts', body)
      response.body
    end

    def get_tag_name
      default_tag_name = "supportbee"
      settings.tagged_name.empty? ? default_tag_name : settings.tagged_name
    end

    def find_contact(requester)
      response = insightly_get(api_url("Contacts?email=#{requester.email}"))
      body = response.body
      body ? body.first : nil
    end

    def insightly_get(url)
      response = http.get url do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Accept'] = 'application/json'
      end
    end

    def fetch_projects
      response = insightly_get(api_url('projects?brief=true'))
      response.body.reject do |project|
        !["not started", "in progress", "deferred"].include?(project['STATUS'].downcase)
      end.to_json
    end

    def fetch_opportunities
      response = insightly_get(api_url('opportunities?brief=true'))
      response.body.reject do |opportunity|
        !["open", "suspended"].include?(opportunity['OPPORTUNITY_STATE'].downcase)
      end.to_json
    end

    def fetch_users
      response = insightly_get(api_url('users'))
      response.body.to_json
    end

    def api_url(resource="", options={})
      version = options.delete(:version) || "2.1"
      "https://api.insight.ly/v#{version}/#{resource}"
    end

    def api_post(resource, body = nil)
      http.post api_url(resource) do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json if body
      end
    end

    def contact_link(contact)
      "<a href='https://#{settings.subdomain}.insight.ly/Contacts/Details/#{contact['CONTACT_ID']}'>View #{contact['FIRST_NAME']}'s profile on Insightly.</a>"
    end

    def task_created_html(task)
      html = ''
      html << "Insightly Task Created!<br/>"
      html << "<b><a href='https://#{settings.subdomain}.insight.ly/Tasks/TaskDetails/#{task['TASK_ID']}'>#{task['Title']}</a></b>"
    end

    def existing_contact_info(contact)
      html = ""
      html << "<b>#{contact['FIRST_NAME']} #{contact['LAST_NAME']}</b> is already an Insightly Contact.<br/>"
      html << contact_link(contact)
    end

    def created_contact_info(contact)
      html = ""
      html << "Added <b>#{contact['FIRST_NAME']} #{contact['LAST_NAME']}</b> to Insightly Contacts.<br/>"
      html << contact_link(contact)
    end

    def generate_note_content(ticket)
      note = "<a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
      note << "<br/> #{ticket.content.text}"

      unless ticket.content.attachments.blank?
        note << "<br/><br/><strong>Attachments</strong><br/>"
        ticket.content.attachments.each do |attachment|
          note << "<a href='#{attachment.url.original}'>#{attachment.filename}</a>"
          note << "<br/>"
        end
      end

      note
    end
  end
end
