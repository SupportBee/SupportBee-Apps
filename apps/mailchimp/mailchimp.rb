module Mailchimp
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      return true
    end

    # Handle all events
    def all_events
      return true
    end
  end
end

module Mailchimp
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Mailchimp
  class Base < SupportBeeApp::Base
    # Define Settings
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

