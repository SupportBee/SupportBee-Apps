module Insightly
  module EventHandler
    def ticket_created
      ticket = payload.ticket
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
        puts "#{e.message}\n#{e.backtrace}"
        [500, e.message]
      end
      [200, "Contact sent"]
    end
  end

  module ActionHandler
    def button
     ticket = payload.tickets.first
     begin
       response = create_task(payload.overlay.title, payload.overlay.description)
       html = comment_html(response)
       comment_on_ticket(ticket, html)
     rescue Exception => e
        puts "#{e.message}\n#{e.backtrace}"
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

    def validate
      errors[:flash] = ["Please fill in all the required fields"] if settings.url.blank? or settings.api_key.blank?
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
      response
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
      response = http.post api_url('Contacts') do |req|
        req.headers['Authorization'] = 'Basic ' + Base64.encode64(settings.api_key)
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end
      response.body
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

    def comment_html(response)
      html = ''
      html << "Insightly Task Created!<br/>"
      html << "<b>#{response.body['TITLE']}</b>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

    def existing_contact_info(contact)
      html = ""
      html << "<b>#{contact['FIRST_NAME']} #{contact['LAST_NAME']}</b> is already a Insightly Contact."
    end

    def created_contact_info(contact)
      html = ""
      html << "Added <b>#{contact['FIRST_NAME']} #{contact['LAST_NAME']}</b> to Insightly Contacts."
    end
  end
end

