module SupportBee
  class UserAssignment < Resource
    def initialize(data={}, payload={})
      super(data, payload)
      assignee.user = SupportBee::User.new(auth, assignee.user)
    end

    def refresh
      raise NotImplementedError.new('UserAssignment cannot be refreshed')
    end
  end
end
