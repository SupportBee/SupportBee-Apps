module Webhook
  module EventHandler
    def all_events
      urls_collection.post_to_all({payload: payload.raw_payload}.to_json)
    end
  end
end

module Webhook
  class Base < SupportBeeApp::Base
    text :urls,
         :required => true,
         :hint => 'If you need multiple URLs separate them with a comma (E.g.: http://example1.com, http://example2.com)'

    white_list :urls

    def validate
      errors.merge!(urls_collection.errors)
      is_valid = errors.empty?
      is_valid
    end

    def urls_collection
      @urls_collection ||= URLsCollection.new(settings.urls)
    end
  end
end
