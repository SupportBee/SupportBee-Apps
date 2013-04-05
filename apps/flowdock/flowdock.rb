module Flowdock
  module EventHandler
    def ticket_created
      return unless settings.notify_ticket_created.to_s == '1'
      ticket = payload.ticket
      paste_in_flowdock :content => ticket.content.html,
                        :subject => ticket.subject,
                        :link => get_link,
                        :poster => ticket.requester,
                        :tags => ['new_ticket']
    end

    def agent_reply_created
      return unless settings.notify_agent_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      paste_in_flowdock :content => reply.content.html,
                        :subject => ticket.subject,
                        :link => get_link,
                        :poster => reply.replier,
                        :tags => ['agent_reply']
    end

    def customer_reply_created
      return unless settings.notify_customer_reply_created.to_s == '1'
      ticket = payload.ticket
      reply = payload.reply
      paste_in_flowdock :content => reply.content.html,
                        :subject => ticket.subject,
                        :link => get_link,
                        :poster => reply.replier,
                        :tags => ['customer_reply']
    end

    def comment_created
      return unless settings.notify_comment_created.to_s == '1'
      ticket = payload.ticket
      comment = payload.comment
      paste_in_flowdock :content => comment.content.html,
                        :subject => ticket.subject,
                        :link => get_link,
                        :poster => comment.commenter,
                        :tags => ['comment']
    end
  end
end

module Flowdock
  class Base < SupportBeeApp::Base
    string :token, :required => true, :label => 'Flow API Token'
    boolean :notify_ticket_created, :default => true, :label => 'Notify when Ticket is created'
    boolean :notify_customer_reply_created, :default => true, :label => "Notify when a customer replied"
    boolean :notify_agent_reply_created, :default => true, :label => "Notify when an agent replies"
    boolean :notify_comment_created, :default => true, :label => "Notify when a comment is posted"

    white_list :notify_ticket_created, :notify_agent_reply_created, :notify_customer_reply_created, :notify_comment_created

    private 

    def get_link
      "https://#{auth.subdomain}.supportbee.com/tickets/#{payload.ticket.id}"
    end

    def paste_in_flowdock(options)
      puts options.inspect
      get_room(options[:poster]).push_to_team_inbox :subject => options[:subject],
                                          :content => options[:content],
                                          :link => options[:link],
                                          :tags => options[:tags]
    end

    def get_room(poster)
      @client = Flowdock::Flow.new(:api_token => settings.token,
        :source => "SupportBee", :from => {:name => poster.name, :address => poster.email})
    end
  end
end
