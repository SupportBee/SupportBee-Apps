module Dummy
  module EventHandler
    def ticket_created; end
    def ticket_updated; end

    def reply_created; end
    def reply_updated; end
  end
end

module Dummy
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Dummy
  class Base < SupportBeeApp::Base
    string :name, :required => true, :hint => 'A Dummy Name'
    password :key, :required => true, :label => 'Token'
    boolean :active, :default => true
  end
end
