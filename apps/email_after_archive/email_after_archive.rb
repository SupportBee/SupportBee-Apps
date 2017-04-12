#
# This integration is retired
#

module EmailAfterArchive
  module EventHandler    
    def ticket_archived     
      requester = payload.ticket.requester
      first_name, last_name = requester.name ? requester.name.split : [requester.email, '']
      text = settings.email_body.gsub(/{{FIRST_NAME}}/, first_name).gsub(/{{LAST_NAME}}/, last_name)

      RestClient.post "https://api:#{settings.api_key}@api.mailgun.net/v2/#{settings.mailgun_domain}/messages",
        :from =>  settings.from,
        :to => requester.email,
        :subject => settings.subject,
        :text => text
    end
  end
end

module EmailAfterArchive
  class Base < SupportBeeApp::Base
    # Define Settings
     string :api_key, :label => "Mailgun API Key", :required => true, :hint => 'This is the API Key from mailgun console'
     string :mailgun_domain, :label =>"Mailgun Domain", :required => true, :hint => 'Eg: mvhack.mailgun.org'
     string :from, :required => true, :hint => "The Sender's email"
     string :subject, :required => true, :hint => 'Say Hello to your customers'
     string :email_body, :required => true, :hint => 'The body of the email. You can use {{FIRST_NAME}} and {{LAST_NAME}}'        
  end
end

