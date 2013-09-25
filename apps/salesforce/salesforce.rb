module Salesforce
  module EventHandler
    def ticket_created
      @client = setup_saleforce
      ticket = payload.ticket
      requester = ticket.requester
      create_new_contact(requester)

    end
  end
end

module Salesforce
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Email'
    string :password, :required => true, :label => 'Password', :hint => 'Password'
    string :security_token, :required => true, :label => 'Security Token', :hint => 'If you clicked Setup, select My Personal Information | Reset My Security Token.'
    boolean :should_create_contact, :default => true, :required => false, :label => 'Create a New Contact in Salesforce if one does not exist'

    white_list :should_create_contact

    def setup_client
      begin
        Restforce.new
          :username => settings.username,
          :password => settings.password,
          :security_token => settings.security_token,
          :client_id => OMNIAUTH_CONFIG['salesforce']['key']
          :client_secret => OMNIAUTH_CONFIG['salesforce']['secret']
       
      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace}"
        [500, e.message]
      end
    end
    
    def create_new_contact(requester)
      create_contact(requester)
    end
    
    def create_contact(requester)
      return unless settings.should_create_contact.to_s == '1'
      new_contact = @client.create('Contact', { :LastName => requester, :Email => requester.email } )
      find_contact(new_contact)
    end

    def find_contact(contact)
      @client.find('Contact', contact)
    end
    
    
  end
end

