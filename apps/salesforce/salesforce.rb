module Salesforce
  module EventHandler
    def ticket_created
      begin
        @client = setup_client
        ticket = payload.ticket
        requester = ticket.requester
        contact = find_email(requester.email)
        unless contact
          return [200, 'Contact creation disabled'] unless settings.should_create_contact.to_s == '1'
          contact = create_new_contact(requester)
          html = new_contact_info_html(contact)
        else
          html = contact_info_html(contact)
        end

        if contact
          send_note(ticket, contact)
        end
        comment_on_ticket(ticket, html)
      rescue Exception => e
        ErrorReporter.report(e, {payload: payload})
        [500, e.message]
      end

      [200, "Ticket sent to Salesforce"]
    end
  end
end

module Salesforce
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Email'
    string :password, :required => true, :label => 'Password'
    string :security_token, :required => true, :label => 'Security Token', :hint => "Login to your SalesForce Account. Navigate to 'Setup > My Personal Information > Reset My Security Token'"
    boolean :should_create_contact, :default => true, :required => false, :label => 'Create a New Contact in Salesforce if one does not exist'

    white_list :should_create_contact

    def setup_client
      Restforce.new :username => settings.username,
        :password => settings.password,
        :security_token => settings.security_token,
        :client_id => OMNIAUTH_CONFIG['salesforce']['key'],
        :client_secret => OMNIAUTH_CONFIG['salesforce']['secret']
    end

    def create_new_contact(requester)
      create_contact(requester)
    end

    def create_contact(requester)
      return unless settings.should_create_contact.to_s == '1'
      firstname = split_name(requester).first
      lastname = split_name(requester).last
      new_contact_id = @client.create('Contact', { "FirstName" => firstname, "LastName" => lastname, "Email" => requester.email } )
      find_contact_by_id(new_contact_id)
    end

    def find_contact_by_id(id)
      @client.find('Contact', id)
    end

    def split_name(requester)
      requester.name ? requester.name.split(' ') : [requester.email,'']
    end

    def new_contact_info_html(contact)
      "Added #{contact.Name} to Salesforce... \n #{contact_url(contact)}"
    end

    def contact_info_html(contact)
      html = ""
      html << "#{contact.Name} \n"
      html << "#{contact.Department} \n" if contact.respond_to?(:Department)
      html << contact_url(contact)
      html
    end

    def find_email(email)
      email_id = @client.search("FIND {#{email}}")
      find_contact_by_id(email_id[0]['Id']) rescue nil
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

    def contact_url(contact)
      "<a href='#{@client.instance_url}/#{contact.Id}'>View #{contact.Name}'s profile on Salesforce</a>"
    end

    def send_note(ticket, contact)
      @client.create('Note', { "Body" => generate_note_content(ticket), "ParentId" => contact.Id, "Title" => ticket.summary })

    end

    def generate_note_content(ticket)
      note = ""
      note << ticket.summary + "\n"
      note << "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
      note
    end

  end
end
