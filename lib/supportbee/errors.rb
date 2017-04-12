module SupportBee
  class InvalidAuthToken < ::StandardError; end
  class InvalidSubDomain < ::StandardError; end
  class InvalidRequestError < ::StandardError; end
  class AssignmentError < ::StandardError; end
  class TicketUpdateError < ::StandardError; end
end
