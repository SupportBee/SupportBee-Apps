module Mailchimp
  module ActionHandler
    def button
      ticket = payload.tickets.first

      begin
        add_to_list(ticket)
      rescue Exception => e
        return [ 500, e.message ]
      end

      [200, "Success"]
    end

    # End point to fetch all the lists
    def lists
      begin
        all_lists = get_lists

        return [ 200, all_lists ]
      rescue Exception => e
        return [ 500, e.message ]
      end
    end
  end
end

module Mailchimp
  class Base < SupportBeeApp::Base
    
    # Define Settings
    string :api_key, :required => true, :hint => 'Get you API key at: http://kb.mailchimp.com/article/where-can-i-find-my-api-key'

    # Return all lists from MailChimp
    def get_lists
      response = http_post api_url("/lists/list.json") do |req|
        req.body = { 'apikey' => settings.api_key }.to_json
        req.headers['Content-Type'] = 'application/json'
      end

      return handle_response(response)
    end

    # Return the list id that was was given by the user as an input
    def list_id
      payload.overlay.lists_select
    end

    # Add requester email to a list
    def add_to_list(ticket)
      response = http_post api_url("/lists/subscribe") do |req|
        req.body = { 'apikey' => settings.api_key, 'id' => list_id, 'email' => ticket.requester.email, 'name' => ticket.requester.name }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      
      return handle_response(response)
    end

    private

    # Helper to make the mailchimp API url
    def api_url(path)
      splitted = settings.api_key.to_s.split("-")
      version = "2.0"

      if splitted.length == 2
        ds = splitted[1]
        return "https://#{ds}.api.mailchimp.com/#{version}#{path}"
      end

      raise "Invalid API key format"

    end

    # Helper method to handle mailchimp response
    def handle_response(response)
      response_body = response.body

      if response_body['data']
        return response_body['data']
      end

      raise response_body['error']
    end

  end
end

