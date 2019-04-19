module Insightly
  module EventHandler
    def ticket_created
      return unless settings.sync_contacts.to_s == '1'
      return if spam_or_trash_ticket?

      contact = find_contact(requester)
      html = ''

      if contact
        html = existing_contact_html(contact)
      else
        contact = create_contact(requester)
        html = new_contact_html(contact)
      end
      return unless contact

      create_note_with_ticket_content(ticket) if create_note_with_ticket_content?
      ticket.comment(html: html)
    end

    private

    def spam_or_trash_ticket?
      ticket.trash || ticket.spam
    end

    def requester
      ticket.requester
    end

    def ticket
      @ticket ||= payload.ticket
    end

    def create_note_with_ticket_content?
      settings.send_ticket_content.to_s == "1"
    end
  end

  module ActionHandler
    def button
     ticket = payload.tickets.first
     task = create_task(payload.overlay.title, payload.overlay.description, ticket.requester)
     note = create_note(payload.overlay.title, payload.overlay.description, ticket.requester)
     html = new_task_html(task)
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

    def create_note_with_ticket_content(ticket)
      create_note(ticket.subject, new_note_with_ticket_content_html(ticket), ticket.requester)
    end

    def find_or_create_contact(requester)
      contact = find_contact(requester)
      return contact unless contact.nil?
      create_contact(requester)
    end

    def create_contact(requester)
      body = {
        contactinfos: [{
          type: 'Email',
          detail: requester.email
        }]
      }
      body[:first_name] = requester.first_name unless blank?(requester.first_name)
      body[:last_name] = requester.last_name unless blank?(requester.last_name)
      body[:tags] = [{ tag_name: get_tag_name }] if settings.tag_contacts.to_s == "1"
      response = api_post('Contacts', body)
      response.body
    end

    def blank?(object)
      return true if object.nil?
      return true if object == ''
      false
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

    def api_url(resource = "", options = {})
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

    def existing_contact_html(contact)
      contact_first_name, contact_last_name = contact['FIRST_NAME'], contact['LAST_NAME']

      html = ""
      html << "<b>#{contact_first_name} #{contact_last_name}</b> is already an Insightly Contact.<br/>"
      html << contact_link(contact)
    end

    def new_contact_html(contact)
      contact_first_name, contact_last_name = contact['FIRST_NAME'], contact['LAST_NAME']

      html = ""
      html << "Added <b>#{contact_first_name} #{contact_last_name}</b> to Insightly Contacts.<br/>"
      html << contact_link(contact)
    end

    def contact_link(contact)
      contact_url, contact_first_name = contact_url(contact), contact['FIRST_NAME']
      "<a href='#{contact_url}'>View #{contact_first_name}'s profile on Insightly.</a>"
    end

    def contact_url(contact)
      contact_id = contact['CONTACT_ID']
      if company_uses_insightly_new_design?
        "https://#{settings.subdomain}.insightly.com/list/contact/?blade=/details/Contacts/#{contact_id}"
      else
        "https://#{settings.subdomain}.insight.ly/Contacts/Details/#{contact_id}"
      end
    end

    def new_note_with_ticket_content_html(ticket)
      html = "<a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
      html << "<br/> #{ticket.content.text}"

      unless ticket.content.attachments.blank?
        html << "<br/><br/><strong>Attachments</strong><br/>"
        ticket.content.attachments.each do |attachment|
          html << "<a href='#{attachment.url.original}'>#{attachment.filename}</a>"
          html << "<br/>"
        end
      end

      html
    end

    def new_task_html(task)
      html = ''
      html << "Insightly Task Created!<br/>"
      task_title, task_url = task['Title'], task_url(task)
      html << "<b><a href='#{task_url}'>#{task_title}</a></b>"
    end

    def task_url(task)
      task_id = task['TASK_ID']
      if company_uses_insightly_new_design?
        "https://#{settings.subdomain}.insightly.com/list/task/?blade=/details/Tasks/#{task_id}"
      else
        "https://#{settings.subdomain}.insight.ly/Tasks/TaskDetails/#{task_id}"
      end
    end

    def company_uses_insightly_new_design?
      settings.subdomain == "crm.na1"
    end
  end
end
