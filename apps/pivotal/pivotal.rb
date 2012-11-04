module Pivotal
  module EventHandler
    #def ticket_created
    #end
    def ticket_created
      response = http_post "https://www.pivotaltracker.com/services/v3/projects/#{settings.project_id}/stories" do |req|
        req.headers['X-TrackerToken'] = settings.token 
        req.headers['Content-Type'] = 'application/xml'
        req.body = "<story><story_type>feature</story_type><name>#{payload.ticket.subject}</name></story>"
      end
      puts response.status
      puts response.body
    end
  end
  
  module ActionHandler
    def button
      # Handle Action here
      response = http_post "https://www.pivotaltracker.com/services/v3/projects/#{settings.project_id}/stories" do |req|
        req.headers['X-TrackerToken'] = settings.token 
        req.headers['Content-Type'] = 'application/xml'
        req.body = "<story><story_type>feature</story_type><name>#{payload.tickets.first.subject}</name></story>"
      end
      [200, "Success"]
    end

    def all_actions
    end

  end
end



module Pivotal
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'Token'
    string :project_id, :required => true, :label => 'Project ID'
    
    #string :subdomain, :required => true, :label => 'Subdomain'
    #string :token, :required => true, :label => 'Token'
    #string :room, :required => true, :label => 'Room'
    #
    private

    def setup


    end

  end
end
