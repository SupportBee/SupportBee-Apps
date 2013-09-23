module Pivotaltracker
  module ActionHandler
    def button
      ticket = payload.tickets.first
      begin
       response =  create_story(payload.overlay.title, payload.overlay.description) 
       return [500, "Unauthorized. Please check the Project ID and Token"] unless response

       html = comment_html(response, payload.overlay.title)
       comment_on_ticket(ticket, html)
      rescue Exception => e
        return [500, e.message]
      end
      
      [200, "Ticket sent to Pivotal Tracker"]
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
      response if response.status == 200
    end
    
    def comment_html(response, title)
      hash_response = Hash.from_xml(response.body)
      "Pivotal Tracker Story Created! \n <a href='https://www.pivotaltracker.com/s/projects/#{hash_response['story']['project_id']}/stories/#{hash_response['story']['id']}'>#{title}</a>"
    end

    def comment_on_ticket(ticket, html)
       ticket.comment(:html => html)
    end
  end
end
