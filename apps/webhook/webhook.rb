module Webhook
  module EventHandler
    def all_events
      urls_collection.post_to_all({ payload: payload.raw_payload }.to_json)
    end
  end
end

module Webhook
  class Base < SupportBeeApp::Base
    text :urls,
         :required => true,
         :hint => 'If you need multiple URLs, separate them with a comma (E.g.: http://example1.com, http://example2.com)'

    white_list :urls

    def validate
      if urls_collection.valid?
        true
      else
        self.inline_errors.merge!(urls_collection.errors)
        show_error_notification "Invalid URLs"
        false
      end
    end

    private

    def urls_collection
      @urls_collection ||= URLsCollection.new(settings.urls)
    end
  end
end
