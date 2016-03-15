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

    #
    # Old events before Assign to Teams launch
    #

    def ticket_assigned_to_agent
      assignee = payload.assignment.assignee.user
      log_string(action_type: "Assigned to #{assignee.name} (#{assignee.email})")
    end

    def ticket_assigned_to_group
      assignee = payload.assignment.assignee.group
      log_string(action_type: "Assigned to \"#{assignee.name}\" group")
    end

    def ticket_unassigned
      log_string(action_type: 'Unassigned')
    end

    #
    # New events after Assign to Teams launch
    #

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
    # Define Settings
    # string :name, :required => true, :hint => 'Tell me your name'
    # string :username, :required => true, :label => 'User Name'
    # password :password, :required => true
    # boolean :notify_me, :default => true, :label => 'Notify Me'

    # White list settings for logging
    # white_list :name, :username

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
    def log_string(options={})
      message = options[:message] || "#{options[:action_type]}"
      puts payload.inspect unless test_env?
      agent = payload.agent
      message << " by #{agent.name} (#{agent.email})" if agent
      message << " at #{Time.now.utc.strftime("%I:%M %P, %D")} UTC"
      payload.ticket.comment :html => message
    end

    private

    def test_env?
      ENV['RACK_ENV'] == 'test'
    end
  end
end
