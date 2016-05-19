module Webhook
  module EventHandler
    def method_missing(method, *args)
      webhook_urls = settings.urls.split(/\s*,\s*/)
      webhook_urls.each do |url|
        post(url.strip, {payload: payload}.to_json)
      end
    end

    def respond_to?(method)
      method_name_is_in_underscore_format = method =~ /^[\w_]+$/
      method_name_is_in_underscore_format && defined?(payload)
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
