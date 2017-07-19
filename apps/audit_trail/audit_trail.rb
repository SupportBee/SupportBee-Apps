#
# This integration is retired
#

module AuditTrail
  module EventHandler
    def ticket_archived
      log_string(action_type: 'Archived')
    end

    def ticket_unarchived
      log_string(action_type: 'Unarchived')
    end

    def ticket_spammed
      log_string(action_type: 'Spammed')
    end

    def ticket_unspammed
      log_string(action_type: 'Unspammed')
    end

    def ticket_trashed
      log_string(action_type: 'Trashed')
    end

    def ticket_untrashed
      log_string(action_type: 'Untrashed')
    end

    def ticket_assigned_to_user
      assignee = payload.user_assignment.assignee.user
      log_string(action_type: "Assigned to #{assignee.name} (#{assignee.email})")
    end

    def ticket_assigned_to_team
      assignee = payload.team_assignment.assignee.team
      log_string(action_type: "Assigned to \"#{assignee.name}\" team")
    end

    def ticket_unassigned_from_user
      log_string(action_type: 'Unassigned from agent')
    end

    def ticket_unassigned_from_team
      log_string(action_type: 'Unassigned from team')
    end
  end
end

module AuditTrail
  class Base < SupportBeeApp::Base
    def log_string(options = {})
      message = options[:message] || "#{options[:action_type]}"
      agent = payload.agent
      message << " by #{agent.name} (#{agent.email})" if agent
      message << " at #{Time.now.utc.strftime("%I:%M %P, %D")} UTC"
      payload.ticket.comment :html => message
    end
  end
end
