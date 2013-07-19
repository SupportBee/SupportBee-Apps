module Pivotaltracker
  module ActionHandler
    def button

      begin
        create_story(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

    end
  end
end



module Pivotaltracker
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'Token'
    string :project_id, :required => true, :label => 'Project ID'

    private

    def create_story(story_name, description)
      response = http_post "https://www.pivotaltracker.com/services/v3/projects/#{settings.project_id}/stories" do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/xml'
        req.body = "<story><story_type>feature</story_type><name><![CDATA[#{story_name}]]></name><description><![CDATA[#{description}]]></description></story>"
      end
   
      if response.status == 200
        result = [200, "Ticket sent to Pivotal Tracker"] if response.status == 200
      elsif response.status == 401
        result = [500, "Unauthorized. Please check the Project ID and Token"]
      end
     
    end

  end
end
