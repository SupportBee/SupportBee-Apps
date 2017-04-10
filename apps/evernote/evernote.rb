require "digest/md5"

module Evernote
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      post_ticket(payload.ticket)
    end

    def agent_reply_created
      post_reply(payload.reply, payload.ticket)
    end

    def customer_reply_created
      post_reply(payload.reply, payload.ticket)
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
      content = reply.content.text
      ticket_url = "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
      note.content = generate_note_xml(content, ticket_url)
      createdNote = noteStore.createNote(settings.auth_token, note)
    end

    def post_ticket(ticket)
      noteStore, note = get_notestore
      note.title = "#{ticket.subject} from #{ticket.requester.name} (#{ticket.requester.email})"
      content = ticket.content.text
      ticket_url = "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
      note.content = generate_note_xml(content, ticket_url)
      createdNote = noteStore.createNote(settings.auth_token, note)
    end

    private

    def generate_note_xml(content, ticket_url)
      content = "#{content}\n\nSupportBee Ticket URL:\n#{ticket_url}"
      #user nokogiri to sanitize XML; Adds splitter nodes
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.send(:"x-evernote-splitter", content)
      end
      #remove splitter nodes and other headers
      sanitized_content = builder.to_xml.split('<x-evernote-splitter>')[1].split('</x-evernote-splitter>').first

      sanitized_content = sanitized_content.split("\n").map! do |c| 
        if c.blank?
          "<div><br/></div>"
        else
          "<div>#{c}</div>"
        end
      end.join("\n")

      xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
  #{sanitized_content}
</en-note>
EOF
      xml
    end
  end
end

