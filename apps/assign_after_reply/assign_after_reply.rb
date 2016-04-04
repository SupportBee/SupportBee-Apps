module AssignAfterReply
  module EventHandler
    def agent_reply_created
      ticket = payload.ticket
      has_user_assignee = ticket.respond_to?(:current_user_assignee)
      replier = payload.reply.replier
      return if has_user_assignee and settings.reassign.to_s != '1'
      assign_ticket_to_user(ticket, replier)

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

    def assign_ticket_to_user(ticket, user)
      begin
        ticket.assign_to_user(user.id)
      rescue SupportBee::AssignmentError
        message = "Assign After Reply app couldn't assign the ticket to #{user.name} since #{user.name} isn't a member of the #{ticket.current_team_assignee.team.name} team"
        ticket.comment :html => message
      end
    end
  end
end
