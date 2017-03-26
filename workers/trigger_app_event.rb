class TriggerAppEvent
  include Sidekiq::Worker

  def perform(app_slug, event, data, payload)
    app_class = SupportBeeApp::Base.find_from_slug(app_slug)
    app_class.trigger_event(event, data, payload)
  end
end
