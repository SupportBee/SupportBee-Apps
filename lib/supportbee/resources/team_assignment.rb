module SupportBee
  class TeamAssignment < Resource
    def initialize(data={}, payload={})
      super(data, payload)
      assignee.team = SupportBee::Team.new(auth, assignee.team)
    end

    def refresh
      raise NotImplementedError.new('TeamAssignment cannot be refreshed')
    end
  end
end
