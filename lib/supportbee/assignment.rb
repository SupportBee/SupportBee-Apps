module SupportBee
  class Assignment < Resource
    def initialize(data={}, payload={})
      super(data, payload)
      if assignee
        assignee.user = SupportBee::User.new(auth, assignee.user) if assignee.user?
        assignee.group = SupportBee::Group.new(auth, assignee.group) if assignee.group?
      end
    end

    def refresh
      raise NotImplementedError.new('An Assignment cannot be refreshed')
    end
  end
end
