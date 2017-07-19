module Hipchat
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      ticket = payload.ticket
      send_to_hipchat "<b>New Ticket</b> from #{ticket.requester.name}: <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      send_to_hipchat "<b>Agent Reply</b> from #{reply.replier.name} in <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      send_to_hipchat "<b>Customer Reply</b> from #{reply.replier.name} in <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      ticket = payload.ticket
      comment = payload.comment
      send_to_hipchat "<b>Comment</b> from #{comment.commenter.name} on <a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>#{ticket.subject}</a>"
    end
  end
end

module Hipchat
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'API Token', :hint => "Login to your HipChat account, go to Group admin > Api. Create new admin token if one doesn't exist."
    string :room, :required => true, :label => 'Room (Name)'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => "Notify when a customer replied"
    boolean :notify_agent_reply_created, :default => true, :label => "Notify when an agent replies"
    boolean :notify_comment_created, :default => true, :label => "Notify when a comment is posted"
    boolean :alert_users, :label => 'Alert users on notifications', :hint => 'Alert (play a sound, change tab color etc.) users on notifications. Depends on user preferences in HipChat.'

    white_list :subdomain, :room, :notify_ticket_created, :notify_agent_reply_created, :notify_customer_reply_created, :notify_comment_created
    
    def validate
      unless valid_token_length?
        show_inline_error :token, "We support version 1 of the API. The token you have provided cannot be used with this version. Please follow the instructions below to get the valid API token."
        return false
      end

      result = validate_api_token
      if result['error']
        show_error_notification "#{result['error']['message']}"
        return false
      end

      true
    end

    private 

    def validate_api_token
      response = http_get "https://api.hipchat.com/v1/rooms/message?auth_token=#{settings.token}&auth_test=true"
      response.body
    end

    def valid_token_length? 
      settings.token.length == 30 ? true : false
    end 

    def paste_in_hipchat(text)
      get_room.send('SupportBee', text.slice(0,140), :message_format => 'text')
    end

    def send_to_hipchat(message, options = {})
      enable_user_alerts(options) if settings.alert_users.to_s == '1'
      get_room.send('SupportBee', message, options)
    end

    def enable_user_alerts(options)
      options[:notify] = 1
    end

    def get_room
      @client ||= HipChat::Client.new(settings.token)
      @client[settings.room]
    end
  end
end
