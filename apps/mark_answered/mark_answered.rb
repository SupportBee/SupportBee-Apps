module MarkAnswered
  module EventHandler
  end
end

module MarkAnswered
  module ActionHandler
    def button
      comment = payload.overlay.comment
      tickets = payload.tickets
      tickets.each do |ticket|
        ticket.mark_answered
        comment_html = "#{payload.agent.name} (#{payload.agent.email}) marked this tickat as answered"
        comment_html << " and left a comment:\n\n#{comment}" unless comment.empty?
        ticket.comment :text => comment_html
      end
      [200, "Marked Answered: Updating Screen ..."]
    end
  end
end

module MarkAnswered
  class Base < SupportBeeApp::Base
    # Define Settings
    # string :name, :required => true, :hint => 'Tell me your name'
    # string :username, :required => true, :label => 'User Name'
    # password :password, :required => true
    # boolean :notify_me, :default => true, :label => 'Notify Me'

    # White list settings for logging
    # white_list :name, :username

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
  end
end

