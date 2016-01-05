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

    def ticket_assigned_to_agent
      assignee = payload.assignment.assignee.user
      log_string(action_type: "Assigned to #{assignee.name} (#{assignee.email})")
    end

    def ticket_assigned_to_group
      assignee = payload.assignment.assignee.group
      log_string(action_type: "Assigned to \"#{assignee.name}\" group")
    end

    def ticket_sent_to_group
      group = payload.ticket.group
      log_string(action_type: "Sent to \"#{group.name}\" group")
    end

    def ticket_unassigned
      log_string(action_type: 'Unassigned')
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
      puts payload.inspect
      agent = payload.agent
      message << " by #{agent.name} (#{agent.email})" if agent
      message << " at #{Time.now.utc.strftime("%I:%M %P, %D")} UTC"
      payload.ticket.comment :html => message
    end
  end
end

