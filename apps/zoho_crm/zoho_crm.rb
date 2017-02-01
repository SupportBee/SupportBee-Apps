module ZohoCrm
  module EventHandler
    def ticket_created
      begin
  			ticket = payload.ticket
        return if ticket.trash || ticket.spam

        setup_zoho
        requester = ticket.requester
        contact = find_contact(requester)

        unless contact
          return [200, 'Contact creation disabled'] unless settings.should_create_contact.to_s == '1'

          contact =  create_new_contact(requester)
          html = new_contact_info_html(contact)

        else
          html = contact_info_html(contact)
        end

        send_note(ticket, contact) if contact

        comment_on_ticket(ticket, html)
      rescue Exception => e
        context = ticket.context.merge(company_subdomain: payload.company.subdomain, app_slug: self.class.slug, payload: payload)
        ErrorReporter.report(e, context: context)
        [500, e.message]
      end

      [200, "Ticket sent to Zohocrm"]
    end
  end
end

module ZohoCrm
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'ZohoCRM Auth Token', :hint => 'Login to your ZohoCRM account, go to Setup -> Developer Space -> click on Browser Mode link'
    boolean :should_create_contact, :default => true, :required => false, :label => 'Create a New Contact in Zoho CRM if one does not exist'

    white_list :should_create_contact

    def validate
      return false unless required_fields_present?
      return false unless valid_credentials?
      true
    end

    require 'ruby_zoho'

    def setup_zoho
      RubyZoho.configure do |config|
        config.api_key = settings.api_token
        config.crm_modules = ['Accounts', 'Contacts', 'Leads', 'Potentials']
      end
    end

    def create_new_contact(requester)
      contact =  create_contact(requester)
    end

    def create_contact(requester)
     return unless settings.should_create_contact.to_s == '1'
     firstname = split_name(requester).first
     lastname = split_name(requester).last
     new_contact = RubyZoho::Crm::Contact.new(
                    :first_name => firstname,
                    :last_name => lastname,
                    :email => requester.email
                  )
     created_contact = new_contact.save
     find_contact(created_contact)
    end

    def contact_url(contact)
      "<a href='https://crm.zoho.com/crm/ShowEntityInfo.do?id=#{contact.contactid}&module=Contacts&isload=true'>View #{contact.first_name}'s profile on ZohoCrm</a>"
    end

    def split_name(requester)
      requester.name ? requester.name.split(' ') : [requester.email,'']
    end

    def find_contact(requester)
      RubyZoho::Crm::Contact.find_by_email(requester.email).first rescue nil
    end

    def contact_info_html(contact)
      html = ""
      html << "<b> #{contact.first_name} #{contact.last_name}</b><br/>"
      html << "#{contact.department} <br/>" if contact.respond_to?(:department)
      html << contact_url(contact)
      html
    end

    def new_contact_info_html(contact)
      html = ""
      html << "Added #{contact.first_name} #{contact.last_name} to ZohoCRM... "
      html << contact_url(contact)
      html
    end

     def comment_on_ticket(ticket, html)
        ticket.comment(:html => html)
    end

    def send_note(ticket, contact)
      requestid = contact.id
      ownerid = contact.smownerid
      http_post "https://crm.zoho.com/crm/private/xml/Notes/insertRecords" do |req|
        req.params[:newFormat] = "1"
        req.params[:authtoken] = "#{settings.api_token}"
        req.params[:scope] = "crmapi"
        req.headers['Content-Type'] = "application/xml"
        req.body = %Q(<Notes><row no="1"><FL val="entityId">#{requestid}</FL><FL val="SMOWNERID">#{ownerid}</FL><FL val="Note Title">New Ticket</FL><FL val="Note Content">#{generate_note_content(ticket)}</FL></row> </Notes>)
        req.params[:xmlData] = req.body
      end

    end

    def generate_note_content(ticket)
      note = ""
      note << ticket.summary + "\n"
      note << "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
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
      response = get_admin_users
      if api_response_has_admin_users?(response)
        true
      else
        errors[:flash] = "Invalid API Token. Please verify the entered details"
        false
      end
    end

    def get_admin_users
      http_get('https://crm.zoho.com/crm/private/json/Users/getUsers') do |req|
        req.params['scope'] = 'crmapi'
        req.params['authtoken'] = settings.api_token
        req.params['type'] = 'AdminUsers'
      end
    end

    def api_response_has_admin_users?(response)
      JSON.parse(response.body).has_key?("users")
    end

  end
end
