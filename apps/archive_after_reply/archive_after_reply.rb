module ArchiveAfterReply
  module EventHandler
    def agent_reply_created
      ticket = payload.ticket
      ticket.archive unless ticket.archived
      return true
    end
  end
end

module ArchiveAfterReply
  class Base < SupportBeeApp::Base
  end
end
