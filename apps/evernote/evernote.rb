require "digest/md5"

module Evernote
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      post_ticket(payload.ticket)
      true
    end

    def agent_reply_created
      post_reply(payload.reply, payload.ticket)
      true
    end

    def customer_reply_created
      post_reply(payload.reply, payload.ticket)
      true
    end

  end
end

module Evernote
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, :required => true, :hint => 'Get your auth token at https://www.evernote.com/api/DeveloperToken.action'
    string :notebook_name, :required => false, :label => 'Name of the Notebook', :hint => 'Leave blank for default notebook'
    # password :password, :required => true
    boolean :send_replies, :default => true, :label => 'Send Replies to Evernote?'

    # White list settings for logging
    # white_list :name, :username

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
    
    private

    def get_notestore
      evernoteHost = "www.evernote.com"
      userStoreUrl = "https://#{evernoteHost}/edam/user"

      userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
      userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
      userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)

      noteStoreUrl = userStore.getNoteStoreUrl(settings.auth_token)

      noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
      noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
      noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

      # List all of the notebooks in the user's account
      notebooks = noteStore.listNotebooks(settings.auth_token)
      defaultNotebook = notebooks.first

      unless settings.notebook_name.blank?
        notebooks.each do |notebook|
          if settings.notebook_name.casecmp(notebook.name) == 0 
            defaultNotebook = noteStore.getNotebook(settings.auth_token, notebook.guid)
          end
        end
      end

      note = Evernote::EDAM::Type::Note.new
      note.notebookGuid = defaultNotebook.guid 
      [noteStore, note]
    end

    def post_reply(reply,ticket)
      return unless settings.send_replies.to_s == '1'
      noteStore, note = get_notestore

      note.title = "RE: #{ticket.subject} from #{reply.replier.name} (#{reply.replier.email})"

note.content = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
  #{reply.content.text.gsub('\n','<br/>')}
  <br/>
  https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}
</en-note>
EOF

      createdNote = noteStore.createNote(settings.auth_token, note)

    end

    def post_ticket(ticket)

      noteStore, note = get_notestore

      note.title = "#{ticket.subject} from #{ticket.requester.name} (#{ticket.requester.email})"

note.content = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
  #{ticket.content.text.gsub('\n','<br/>')}
  <br/>
  https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}
</en-note>
EOF

      createdNote = noteStore.createNote(settings.auth_token, note)

    end
  end

end

