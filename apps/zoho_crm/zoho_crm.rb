module ZohoCrm
  module EventHandler
    def ticket_created

      begin
       	setup_zoho
  			ticket = payload.ticket
        requester = ticket.requester 
 
        contact = find_contact(requester)  
        unless contact
          return [200, 'Contact creation disabled'] unless settings.should_create_contact.to_s == '1'
          contact =  create_new_contact(requester)
          html = new_contact_info_html(contact)
        else
          html = contact_info_html(contact)
        end
      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace}"
        [500, e.message]
      end
      
      comment_on_ticket(ticket, html)
      [200, "Ticket sent to ZohoCRM"]


    end
  end
end

module ZohoCrm
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'ZohoCRM Auth Token', :hint => 'Login to your ZohoCRM account, go to Setup -> Developer Space -> click on Browser Mode link'
    boolean :should_create_contact, :default => true, :required => false, :label => 'Create a New Contact in ZohoCRM if one does not exist'
    
    require 'ruby_zoho'
    def setup_zoho
      RubyZoho.configure do |config|
        config.api_key = settings.api_token   
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
     
    end

    def split_name(requester)
      requester.name ? requester.name.split(' ') : [requester.email,'']
    end
     
    def find_contact(requester)
      contact = RubyZoho::Crm::Contact.find_by_email(requester.email)
      contact ? contact :nil
    end
		
    def contact_info_html(contact)
      html = ""
      html << "<b> #{contact['first_name']} #{contact['last_name']}" 
      html
    end

    def new_contact_info_html(contact)
      html = ""
      html << "Added #{contact['first_name']} to ZohoCRM... "
      html
    end
    
     def comment_on_ticket(ticket, html)
        ticket.comment(:html => html)
    end
  
  end
end

