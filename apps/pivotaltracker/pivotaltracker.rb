module Pivotaltracker
  module ActionHandler
    def button
      ticket = payload.tickets.first
      story = create_story(payload.overlay.title, payload.overlay.description)
      return [500, "Story not sent!"] unless story
      html = story_info_html(story)

      [200, "Success"]
    end

    def projects
      [200, fetch_projects]
    end
  end
end

module Pivotaltracker
  require 'json'

  class Base < SupportBeeApp::Base
    string :token, required: true, label: 'Token'

    def validate
      errors[:flash] = ["Please fill in the Pivotal API Token"] if validate_presence_of_token
      errors.empty? ? true : false
    end

    def validate
      errors[:flash] = ["There seems to problem with your API Token"] unless test_ping.success?
      errors.empty? ? true : false
    end

    def project_id
      # Will return the ID of the selected project from the overlay form
      "1114382"
    end

    private

    def test_ping
      response = http_get projects_url do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/json'
      end
      response
    end

    def validate_presence_of_token
      not(settings.token.blank?)
    end

    def create_story(story_name, description)
      response = http_post stories_url do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          name: story_name,
          description: description,
          labels: [{
            name: 'supportbee'
          }]
        }.to_json
      end
      response if response.status == 200
    end

    def fetch_projects
      response = http_get projects_url do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/json'
      end
      response.body.to_json
    end

    def projects_url
      pivotal_url("projects") 
    end

    def stories_url
      pivotal_url("projects/#{project_id}/stories")
    end

    def pivotal_url(resource="")
      "https://www.pivotaltracker.com/services/v5/#{resource}"
    end

    def story_info_html(story)
      "Pivotal Tracker Story Created! \n <a href='#{story.body['url']}>#{story.body['name']}</a>"
    end
    
    def comment_on_ticket(ticket, html)
      ticket.comment(html: html)
    end
  end
end
