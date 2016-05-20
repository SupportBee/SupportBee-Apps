require_relative '../../lib/app_mixins/proxy_event_handler'

module Webhook
  module EventHandler
    include SupportBee::ProxyEventHandler

    def all_events
      webhook_urls = settings.urls.split(/\s*,\s*/)
      webhook_urls.each do |url|
        post(url.strip, {payload: payload.raw_payload}.to_json)
      end
    end
  end
end

module Webhook
  class Base < SupportBeeApp::Base
    string :urls,
           :required => true,
           :hint => 'If you need multiple URLs separate them with a comma (E.g.: http://example1.com, http://example2.com)'

    white_list :urls

    def post(url, payload)
      connection = Faraday.new(url: url)
      connection.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload
      end
    end
  end
end
