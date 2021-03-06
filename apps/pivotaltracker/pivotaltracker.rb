module Pivotaltracker
  module ActionHandler
    def button
      ticket = payload.tickets.first
      story = create_story(payload.overlay.title, payload.overlay.description)
      unless story
        show_error_notification "There was an error in sending the story. Please try again!"
        return false
      end
      html = story_info_html(story)

      comment_on_ticket(ticket, html)
      show_success_notification "Story sent to your Pivotal Tracker"
    end

    def projects
      [200, fetch_projects]
    end

    def memberships
      [200, fetch_memberships]
    end
  end
end

module Pivotaltracker
  require 'json'

  class Base < SupportBeeApp::Base
    string :token, required: true, label: 'Token', hint: 'Find the token under Profile (in the user menu) > API Token.'

    def validate
      if settings.token.blank?
        show_inline_error :token, "Please enter your Pivotal Tracker API Token"
        return false
      end

      unless test_api_request.success?
        show_error_notification "Invalid API Token"
        return false
      end

      return true
    end

    private

    def test_api_request
      pivotal_get(projects_url)
    end

    def project_id
      payload.overlay.projects_select
    end

    def owner_id
      return [] if payload.overlay.story_owner == "none"
      [payload.overlay.story_owner.to_i]
    end

    def story_type
      payload.overlay.story_type
    end

    def create_story(story_name, description)
      response = http_post stories_url do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          name: story_name,
          description: description,
          story_type: story_type,
          owner_ids: owner_id,
          labels: [{
            name: 'supportbee'
          }]
        }.to_json
      end
      response if response.status == 200
    end

    def pivotal_get(endpoint_url)
      response = http_get endpoint_url do |req|
        req.headers['X-TrackerToken'] = settings.token
        req.headers['Content-Type'] = 'application/json'
      end
      response
    end

    def fetch_projects
      response = pivotal_get(projects_url)
      response.body.to_json
    end

    def fetch_memberships
      response = pivotal_get(memberships_url)
      memberships = []
      response.body.each { |i|
        memberships << i['person']
      }
      memberships.to_json
    end

    def projects_url
      pivotal_url("projects") 
    end

    def stories_url
      pivotal_url("projects/#{project_id}/stories")
    end

    def memberships_url
      pivotal_url("projects/#{project_id}/memberships")
    end

    def pivotal_url(resource="")
      "https://www.pivotaltracker.com/services/v5/#{resource}"
    end

    def story_info_html(story)
      "Pivotal Tracker Story Created! \n <a href=#{story.body['url']}>#{story.body['name']}</a>"
    end
    
    def comment_on_ticket(ticket, html)
      ticket.comment(html: html)
    end
  end
end
