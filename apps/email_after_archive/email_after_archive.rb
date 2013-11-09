module EmailAfterArchive
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      return true
    end

    def ticket_archived
      recd_user = payload.agent.email
      RestClient.post "https://api:#{settings.API_KEY}" \
      "@api.mailgun.net/v2/#{mailgun_domain}/messages",
      :from => "Excited User <rajat188@gmail.com>",
      :to => "#{payload.agent.email}",
      :subject => "#{settings.subject}",
      :text => "#{settings.email_body}"
    end

    # Handle all events
    def all_events
      return true
    end
  end
end

module EmailAfterArchive
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module EmailAfterArchive
  class Base < SupportBeeApp::Base
    # Define Settings
    string :API_KEY, :required => true, :hint => 'This is the API Key from mailgun console'
     string  :subject, :required => true, :hint => 'Say Hello to your customers'
     string :email_body, :required => true, :hint => 'The body of the email'
     string :mailgun_domain, :required => true, :hint => 'The sub domain available in mailgun'
    # string :name, :required => true, :hint => 'Tell me your name'
    # string :username, :required => true, :label => 'User Name'
    # password :password, :required => true
    # boolean :notify_me, :default => true, :label => 'Notify Me'

    # White list settings for logging
    # white_list :name, :username

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
  end
end

