module Webhook
  module EventHandler
    def all_events
      url_collection.post_to_all({ payload: payload.raw_payload }.to_json)
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
      if url_collection.valid?
        true
      else
        self.inline_errors.merge!(url_collection.errors)
        show_error_notification "Invalid URLs"
        false
      end
    end

    private

    def url_collection
      @url_collection ||= URLCollection.new(settings.urls)
    end
  end
end
