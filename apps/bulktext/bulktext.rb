module Bulktext
  module EventHandler
    def ticket_created
      return true unless settings.notify_ticket_created.to_s == '1'
      ticket = payload.ticket
      notify_sms("New Ticket from #{ticket.requester.name || ticket.requester.email} - #{payload.ticket.subject}")
    end

    def customer_reply_created
      puts "customer reply created"
      puts settings
      return true unless settings.notify_customer_reply_created.to_s == '1'
      reply = payload.reply
      notify_sms("New Reply from #{reply.replier.name || reply.replier.email} in #{payload.ticket.subject}")
    end

  end
end

module Bulktext
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Bulktext
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'BulkSMS Username', :hint => "Signup for a BulkSMS account at https://bulksms.vsms.net/"
    password :password, :required => true, :label => 'BulkSMS Password'
    string :msisdn, :required => true, :label => 'Phone Number(s)', :hint => 'Ex: 44123123456,44123123457 (with country code, comma separated)'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when a Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => 'Notify when the Customer replies'


    def notify_sms(message)
      puts message
      http_post "http://bulksms.vsms.net:5567/eapi/submission/send_sms/2/2.0" do |req|
        req.params[:username] = settings.username
        req.params[:password] = settings.password
        req.params[:message] =  message[0...160]
        req.params[:msisdn] = settings.msisdn 
      end
    end

  end
end

