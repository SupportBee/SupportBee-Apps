module Jira
  module EventHandler
    def ticket_created
    end
  end
end

module Jira
  class Base < SupportBeeApp::Base
    #string :subdomain, :required => true, :label => 'Subdomain'
    #string :token, :required => true, :label => 'Token'
    #string :room, :required => true, :label => 'Room'
  end
end
