module MarkAnswered
  module ActionHandler
    def button
      comment = payload.overlay.comment
      tickets = payload.tickets
      tickets.each do |ticket|
        ticket.mark_answered
        comment_html = "#{payload.agent.name} (#{payload.agent.email}) marked this ticket as answered"
        comment_html << " and left a comment:\n\n#{comment}" unless comment.empty?
        ticket.comment :text => comment_html
      end

      show_success_notification "Marked Answered: Updating Screen ..."
    end
  end
end

module MarkAnswered
  class Base < SupportBeeApp::Base
  end
end

