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
      
      send_note(ticket, contact)
      comment_on_ticket(ticket, html)
      [200, "Ticket sent to Zohocrm"]
    end
  end
end

module ZohoCrm
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'ZohoCRM Auth Token', :hint => 'Login to your ZohoCRM account, go to Setup -> Developer Space -> click on Browser Mode link'
    boolean :should_create_contact, :default => true, :required => false, :label => 'Create a New Contact in Zoho CRM if one does not exist'

    white_list :should_create_contact

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
      contact = RubyZoho::Crm::Contact.find_by_email(requester.email)
      contact ? contact :nil
    end
		
    def contact_info_html(contact)
      html = ""
      html << "<b> #{contact.first.first_name} #{contact.first.last_name}</b><br/>"
      html << "#{contact.first.department} <br/>" if contact.first.department
      html << contact_url(contact.first)
      html
    end

    def new_contact_info_html(contact)
      html = ""
      html << "Added #{contact.first.first_name} #{contact.first.last_name} to ZohoCRM... "
      html << contact_url(contact.first)
      html
    end
    
     def comment_on_ticket(ticket, html)
        ticket.comment(:html => html)
    end
    
    def send_note(ticket, contact)
      contactid = contact.first.contactid
      ownerid = contact.first.smownerid

      http_post "https://crm.zoho.com/crm/private/xml/Notes/insertRecords" do |req|
        req.params[:newFormat] = "1"
        req.params[:authtoken] = "#{settings.api_token}"
        req.params[:scope] = "crmapi"
        req.headers['Content-Type'] = "application/xml"
        req.body = %Q(<Notes><row no="1"><FL val="entityId">#{contactid}</FL><FL val="SMOWNERID">#{ownerid}</FL><FL val="Note Title">#{ticket.summary}</FL><FL val="Note Content">"https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"</FL></row> </Notes>)
        req.params[:xmlData] = req.body
      end
     
    end
 
  end
end


