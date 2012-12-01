require "digest/md5"

module Evernote
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      puts "ticket created"
      post_to_evernote(payload.ticket)
      return true
    end

    # Handle all events
    #def all_events
      #return true
    #end
  end
end

module Evernote
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, :required => true, :hint => 'Get your auth token at https://www.evernote.com/Login.action?targetUrl=%2Fapi%2FDeveloperToken.action'
    string :notebook_name, :required => false, :label => 'Name of the Notebook', :hint => 'Leave blank for default notebook'
    # password :password, :required => true
    # boolean :notify_me, :default => true, :label => 'Notify Me'

    # White list settings for logging
    # white_list :name, :username

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules
    
    private

    def post_to_evernote(ticket)

      puts "Post to evernote"
      evernoteHost = "sandbox.evernote.com"
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
      puts "Found #{notebooks.size} notebooks:"
      defaultNotebook = notebooks.first
      puts notebooks.inspect

      unless settings.notebook_name.blank?
        notebooks.each do |notebook|
          the_notebook = notebook if settings.notebook_name.casecmp(notebook.name) == 0 
        end
      end

      the_notebook ||= defaultNotebook

      note = Evernote::EDAM::Type::Note.new
      note.title = "#{ticket.subject} from #{ticket.requester.name} (#{ticket.requester.email})"

note.content = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
  #{ticket.content.body}
  <br/>
  https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}
</en-note>
EOF

      createdNote = noteStore.createNote(settings.auth_token, note)

    end
  end

end

