require 'tilt/haml'

module Vibe
  module EventHandler
    def ticket_created
      ticket = payload.ticket

      params = {
        api_key: settings.api_key,
        email: ticket.requester.email,
        # 0: fetch data from vibe's cache
        # 1: fetch data from vibe's db
        # 2: fetch data from vibe's data providers
        force: 1
      }
      # End the url with a '/', get request is redirected otherwise
      response = http_get 'http://vibeapp.co/api/v1/initial_data/', params
      return unless response.body['success']

      html = render_user_profile(response.body)
      ticket.comment(html: html)
    end
  end
end

module Vibe
  class Base < SupportBeeApp::Base
    string :api_key, :required => true, :label => 'API Key', :hint => 'API Key from http://vibeapp.co/developers/'

    attr_accessor :user_details

    def render_user_profile(user_details)
      self.user_details = user_details

      template_file = File.join File.dirname(__FILE__), 'templates', 'user_profile.haml'
      template = Tilt::HamlTemplate.new(template_file)
      template.render(self)
    end
  end
end
