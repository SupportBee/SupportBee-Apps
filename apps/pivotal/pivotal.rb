module Pivotal
  module ActionHandler
    def button

      begin
        create_story(payload.overlay.name, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Ticket sent to Pivotal Tracker"]

    end
  end
end



module Pivotal
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'Token'
    string :project_id, :required => true, :label => 'Project ID'

    private

    def create_story(story_name, description)
      response = http_post "https://www.pivotaltracker.com/services/v3/projects/#{settings.project_id}/stories" do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/xml'
        req.body = "<story><story_type>feature</story_type><name>#{story_name}</name><description>#{description}</description></story>"
      end
    end

  end
end
