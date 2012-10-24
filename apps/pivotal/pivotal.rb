module Pivotal
  module EventHandler
    def ticket_created
    end
  end
end

module Pivotal
  class Base < SupportBeeApp::Base
    #string :subdomain, :required => true, :label => 'Subdomain'
    #string :token, :required => true, :label => 'Token'
    #string :room, :required => true, :label => 'Room'
  end
end
