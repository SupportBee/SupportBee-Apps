module Webhook
  module EventHandler
    def ticket_created
      return super unless defined?(payload) && payload
      webhook_urls = settings.urls.split(/\s*,\s*/)
      webhook_urls.each do |url|
        post(url.strip, {payload: payload}.to_json)
      end
      true
    end
  end
end

module Webhook
  class Base < SupportBeeApp::Base
    string :urls, :required => true, :hint => 'If you need multiple URLs separate them with a comma (E.g.: http://example1.com, http://example2.com)'
    white_list :urls

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules

    def post(url, payload)
      connection = Faraday.new(url: url)
      connection.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload
      end
    end
  end
end
