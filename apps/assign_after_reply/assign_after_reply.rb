module AssignAfterReply
  module EventHandler
    def agent_reply_created
      ticket = payload.ticket
      assignee = ticket.current_assignee rescue nil
      replier = payload.reply.replier
      return if assignee and settings.reassign.to_s != '1'
      ticket.assign_to_user(replier.id)

      # Archive the ticket unless asked not to
      return if settings.keep_unanswered.to_s == '1'
      ticket.mark_answered
    end
  end
end

module AssignAfterReply
  class Base < SupportBeeApp::Base
    # Define Settings
    boolean :reassign, :default => false, :label => 'Reassign the ticket if another Agent replies'
    boolean :keep_unanswered, :default => false, :label => 'Mark the ticket Unanswered', :hint => '(By default this app assigns a ticket and keeps it answered)'

    # White list settings for logging
    white_list :reassign

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
  end
end
