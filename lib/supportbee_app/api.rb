module SupportBeeApp
  # @todo Add docs
  module Api
    def show_success_notification(message)
      self.success_notification = message
    end

    def show_error_notification(message)
      self.error_notification = message
    end

    def show_inline_error(field_name, message)
      self.inline_errors[field_name] = message
    end

    def report_exception(e)
      ErrorReporter.report(e, context: error_context, tags: error_tags)
    end
  end
end
