module Insightly
  module EventHandler
    def ticket_created
      return unless settings.sync_contacts.to_s == '1'

      ticket = payload.ticket
      return if ticket.trash || ticket.spam
      requester = ticket.requester

      begin
        contact = find_contact(requester)
        html = ''

        if contact
          html = existing_contact_info(contact)
        else
          contact = create_contact(requester)
          html = created_contact_info(contact)
        end

        if contact
          comment_on_ticket(ticket, html)
        end

      rescue Exception => e
        context = ticket.context.merge(company_subdomain: payload.company.subdomain, app_slug: self.class.slug, payload: payload)
        ErrorReporter.report(e, context)
        [500, e.message]
      end
      [200, "Contact sent"]
    end
  end

  module ActionHandler
    def button
     ticket = payload.tickets.first
     begin
       task = create_task(payload.overlay.title, payload.overlay.description)

       html = task_created_html(task)
       comment_on_ticket(ticket, html)

     rescue Exception => e
        context = ticket.context.merge(company_subdomain: payload.company.subdomain, app_slug: self.class.slug, payload: payload)
        ErrorReporter.report(e, context)
        return [500, e.message]
     end
     [200, "Insightly Task Created!"]
    end

    def projects
      [200, fetch_projects]
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
            hint: 'Say https://bfkdlz.insight.ly is your Insightly domain, enter "bfkdlz"'

    string :tagged_name,
            label: 'Tag Name',
            hint: 'The tag name will be used to identify new Insightly contacts created from within SupportBee. If unspecified, default tag name used would be "supportbee". The tagging happens only if the tag new contacts checkbox below is ticked.'

    boolean :tag_contacts,
            label: 'Tag new contacts that are created from within SupportBee with a tag name',
            default: false

    boolean :sync_contacts,
            label: 'Create Insightly Contact with Customer Information',
            default: true

    def validate
      errors[:flash] = ["Please fill in all the required fields"] if settings.subdomain.blank? or settings.api_key.blank?
      errors.empty? ? true : false
    end

    def validate
      errors[:flash] = ["API Key Invalid"] unless test_ping.success?
      errors.empty? ? true : false
    end

    def project_id
      payload.overlay.projects_select
    end

    def responsible_user_id
      payload.overlay.responsible_select
    end

    def owner_user_id
      payload.overlay.owner_select
    end

    private

    def test_ping
      insightly_get(api_url('projects'))
    end

    def create_task(title, description)
      post_body = {
        title: title,
        details: description,
        project_id: project_id,
        completed: false,
        publicly_visible: true,
        responsible_user_id: responsible_user_id,
        owner_user_id: owner_user_id
      }.to_json
      response = http.post api_url('tasks') do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Content-Type'] = 'application/json'
        req.body = post_body
      end
      response.body
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

      response = http.post api_url('Contacts') do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end
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
      response = insightly_get(api_url('projects'))
      response.body.to_json
    end

    def fetch_users
      response = insightly_get(api_url('users'))
      response.body.to_json
    end

    def api_url(resource="")
      "https://api.insight.ly/v2.1/#{resource}"
    end

    def contact_link(contact)
      "<a href='https://#{settings.subdomain}.insight.ly/Contacts/Details/#{contact['CONTACT_ID']}'>View #{contact['FIRST_NAME']}'s profile on Insightly.</a>"
    end

    def task_link(project)
      "<a href='https://#{settings.subdomain}.insight.ly/Contacts/Details/#{contact['CONTACT_ID']}'>View #{contact['FIRST_NAME']}'s profile on Insightly.</a>"
    end

    def task_created_html(task)
      html = ''
      html << "Insightly Task Created!<br/>"
      html << "<b><a href='https://#{settings.subdomain}.insight.ly/Tasks/TaskDetails/#{task['TASK_ID']}'>#{task['Title']}</a></b>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
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
  end
end
