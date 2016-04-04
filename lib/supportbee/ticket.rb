module SupportBee
  class Ticket < Resource
    class << self
      def list(auth={},params={})
        response = api_get(resource_url,auth,params)
        ticket_array_from_multi_response(response, auth)
      end

      def search(auth={}, params={})
        return if params[:query].blank?
        response = api_get("#{resource_url}/search",auth,params)
        ticket_array_from_multi_response(response, auth)
      end

      def create(auth={},params={})
        ticket_attributes = {:content_attributes => {}}
        ticket_attributes[:requester_name] = params.delete(:requester_name)
        ticket_attributes[:requester_email] = params.delete(:requester_email)
        ticket_attributes[:subject] = params.delete(:subject)
        ticket_attributes[:content_attributes][:body] = params.delete(:text) if params[:text]
        ticket_attributes[:content_attributes][:body_html] = params.delete(:html) if params[:html]

        post_body = {:ticket => ticket_attributes}
        response = api_post(resource_url,auth,{body: post_body})
        self.new(auth,response.body['ticket'])
      end

      private

      def ticket_array_from_multi_response(response, auth)
        tickets = []
        result = Hashie::Mash.new
        response.body.keys.each do |key|
          if key == 'tickets'
            response.body[key].each do |ticket|
              tickets << self.new(auth,ticket)
            end
          else
            result[key] = response.body[key]
          end
        end
        result.tickets = tickets
        result
      end
    end

    def update(params={})
      ticket_attributes = {}
      if params[:requester_email]
        ticket_attributes[:requester_email] = params.delete(:requester_email)
        ticket_attributes[:requester_name] = params.delete(:requester_name)
      end
      ticket_attributes[:subject] = params.delete(:subject) unless params[:subject].blank?
      put_body = {ticket: ticket_attributes}
      api_put(resource_url, {body: put_body})
      refresh
    end

    def archive
      archive_url = "#{resource_url}/archive"
      api_post(archive_url)
      refresh
    end

    def unarchive
      archive_url = "#{resource_url}/archive"
      api_delete(archive_url)
      refresh
    end

    def mark_answered
      archive_url = "#{resource_url}/answered"
      api_post(archive_url)
      refresh
    end

    def mark_unanswered
      archive_url = "#{resource_url}/answered"
      api_delete(archive_url)
      refresh
    end

    def assign_to_user(user)
      user_id = user.kind_of?(SupportBee::User) ? user.id : user
      assignment_url = "#{resource_url}/user_assignment"
      post_data = { :user_assignment => { :user_id => user_id }}
      response = api_post(assignment_url, :body => post_data)
      refresh

      begin
        SupportBee::UserAssignment.new(@params, response.body['user_assignment'])
      rescue => e
        LOGGER.warn "__ASSIGN_TO_USER_FAILED__#{e.message}"
        LOGGER.warn "__ASSIGN_TO_USER_FAILED__#{e.backtrace}"
        LOGGER.warn "__ASSIGN_TO_USER_FAILED__#{response.inspect}"
      end
    end

    def assign_to_team(team)
      team_id = team.kind_of?(SupportBee::Team) ? team.id : team
      assignment_url = "#{resource_url}/team_assignment"
      post_data = { :team_assignment => { :team_id => team_id }}
      response = api_post(assignment_url, :body => post_data)
      refresh

      SupportBee::TeamAssignment.new(@params, response.body['team_assignment'])
    end

    def unassign
      assignment_url = "#{resource_url}/assignments"
      api_delete(assignment_url)
      refresh
    end

    def star
      star_url = "#{resource_url}/star"
      api_post(star_url)
      refresh
    end

    def unstar
      unstar_url = "#{resource_url}/star"
      api_delete(unstar_url)
      refresh
    end

    def spam
      spam_url = "#{resource_url}/spam"
      api_post(spam_url)
      refresh
    end

    def unspam
      unspam_url = "#{resource_url}/spam"
      api_delete(unspam_url)
      refresh
    end

    def trash
      trash_url = "#{resource_url}/trash"
      api_post(trash_url)
      refresh
    end

    def untrash
      untrash_url = "#{resource_url}/trash"
      api_delete(untrash_url)
      refresh
    end

    def replies(refresh=false)
      refresh = true unless @replies
      if refresh
        replies_url = "#{resource_url}/replies"
        response = api_get(replies_url)
        @replies = to_replies_array(response).replies
      end
      @replies
    end

    def refresh_reply(reply_id)
      replies_url = "#{resource_url}/replies/#{reply_id}"
      response = api_get(replies_url)
      SupportBee::Reply.new(@params, response.body['reply'])
    end

    def reply(params={})
      post_body = { :reply => {} }
      content_attributes = {}
      content_attributes[:body] = params.delete(:text) if params[:text]
      content_attributes[:body_html] = params.delete(:html) if params[:html]
      content_attributes[:attachment_ids] = params.delete(:attachment_ids) if params[:attachment_ids]
      post_body[:reply][:content_attributes] = content_attributes
      params[:body] = post_body
      replies_url = "#{resource_url}/replies"
      response = api_post(replies_url,params)
      refresh
      SupportBee::Reply.new(@params, response.body['reply'])
    end

    def comments(refresh=false)
      refresh = true unless @comments
      if refresh
        comments_url = "#{resource_url}/comments"
        response = api_get(comments_url)
        @comments = to_comments_array(response).comments
      end
      @comments
    end

    def comment(params={})
      post_body = { :comment => {} }
      content_attributes = {}
      content_attributes[:body] = params.delete(:text) if params[:text]
      content_attributes[:body_html] = params.delete(:html) if params[:html]
      content_attributes[:attachment_ids] = params.delete(:attachment_ids) if params[:attachment_ids]
      post_body[:comment][:content_attributes] = content_attributes
      params[:body] = post_body
      comments_url = "#{resource_url}/comments"
      response = api_post(comments_url,params)
      refresh
      SupportBee::Comment.new(@params, response.body['comment'])
    end

    def labels_list(refresh=false)
      refresh = true unless @labels
      unless refresh
        @labels = []
        labels.each do |label|
          @labels << SupportBee::Label.new(@params, label)
        end
      end
      @labels
    end

    def has_label?(label_name)
      not(labels_list.select{|label| label.name == label_name}.empty?)
    end

    def find_label(label_name)
      SupportBee::Label.find_by_name(label_name,@params)
    end

    def add_label(label_name)
      return if has_label?(label_name)
      return unless find_label(label_name)
      labels_url = "#{resource_url}/labels/#{label_name}"
      api_post(labels_url)
      refresh
    end

    def remove_label(label_name)
      return unless has_label?(label_name)
      labels_url = "#{resource_url}/labels/#{label_name}"
      api_delete(labels_url)
      refresh
    end

    private

    def to_replies_array(response)
      replies = []
      result = Hashie::Mash.new
      response.body.keys.each do |key|
        if key == 'replies'
          response.body[key].each do |reply|
            replies << SupportBee::Reply.new(auth,reply)
          end
        else
          result[key] = response.body[key]
        end
      end
      result.replies = replies
      result
    end

    def to_comments_array(response)
      comments = []
      result = Hashie::Mash.new
      response.body.keys.each do |key|
        if key == 'comments'
          response.body[key].each do |comment|
            comments << SupportBee::Comment.new(auth,comment)
          end
        else
          result[key] = response.body[key]
        end
      end
      result.comments = comments
      result
    end
  end
end
