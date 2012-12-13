module AssignAfterReply
  module EventHandler
    def agent_reply_created
      ticket = payload.ticket
      assignee = ticket.current_assignee rescue nil
      replier = payload.reply.replier
      return if assignee and settings.reassign.to_s != '1'
      payload.ticket.assign_to_user(replier.id)
    end
  end
end

module AssignAfterReply
  class Base < SupportBeeApp::Base
    # Define Settings
    boolean :reassign, :default => false, :label => 'Reassign the ticket if another Agent replies'

    # White list settings for logging
    white_list :reassign

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
  end
end

