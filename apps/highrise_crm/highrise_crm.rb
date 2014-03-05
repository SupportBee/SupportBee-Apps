module HighriseCRM
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester

      setup_highrise
      make_old_settings_compatible

      if settings.associate_ticket_with_company.to_s == '1'
        if company = find_company(requester)
          ticket.comment(:html => company_info_html(company))
        else
          if company = create_company(requester)
            ticket.comment(:html => new_company_info_html(company))
          end
        end
      elsif settings.associate_ticket_with_person.to_s == '1'
        if person = find_person(requester)
          ticket.comment(:html => person_info_html(person))
        else
          if person = create_person(requester)
            ticket.comment(:html => new_person_info_html(person))
          end
        end
      end

      subject = person || company
      return unless subject
      note_content = generate_note_content(ticket)
      subject_type = subject.class.name.demodulize
      note = Highrise::Note.new(subject_id: subject.id, subject_type: subject_type, body: note_content)
      return false unless note.save

      return true unless settings.associate_reply_with_comment.to_s == '1'

      store_note_id(ticket.id, note.id)
      return true
    end

    def agent_reply_created
      header = agent_reply_header(payload.reply)
      create_comment(header: header)
    end

    def customer_reply_created
      header = customer_reply_header(payload.reply)
      create_comment(header: header)
    end
  end
end

module HighriseCRM
  class Base < SupportBeeApp::Base
    # Define Settings
    string :auth_token, :required => true, :hint => 'Highrise Auth Token'
    string :subdomain, :required => true, :label => 'Highrise Subdomain'

    boolean :associate_ticket_with_person, :default => true, :label => 'Associate Ticket with a Person in Highrise'
    boolean :associate_ticket_with_company, :label => 'Associate Ticket with a Company in Highrise', :hint => "`Associate Ticket with a Person in Highrise` will be ignored"
    boolean :should_create_person, :default => true, :label => 'Create a New Person / Company in Highrise if one does not exist'
    boolean :return_ticket_content, :label => 'Send ticket content to Highrise'

    boolean :associate_reply_with_comment, :label => 'Associate Reply with a Comment on Highrise'

    # White list settings for logging
    white_list :subdomain, :should_create_person

    def find_person(requester)
      people = Highrise::Person.search(:email => requester.email)
      people.length > 0 ? people.first : nil
    end

    def find_company(requester)
      Highrise::Company.search(:email => requester.email).first
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name, last_name = requester.name ? requester.name.split : [requester.email,'']
      person = Highrise::Person.new(:first_name => first_name,
                                    :last_name => last_name,
                                    :contact_data => {
                                      :email_addresses => [
                                        :email_address => {:address => requester.email}
                                      ]
                                    })
      if person.save
        return person
      else
        # Cannot do anything
      end
      return nil
    end

    def create_company(requester)
      return unless settings.should_create_person.to_s == '1'

      company = Highrise::Company.new({
        name: requester.name,
        contact_data: {
          email_addresses: {
            email_address: {
              address: requester.email,
              location: 'Work'
            }
          }
        }
      })
      return company if company.save
    end

    def setup_highrise
      Highrise::Base.site = "https://#{settings.subdomain}.highrisehq.com"
      Highrise::Base.user = settings.auth_token
      Highrise::Base.format = :xml
    end

    def make_old_settings_compatible
      {
        'associate_ticket_with_person' => '1',
        'associate_ticket_with_company' => '0'
      }.each do |name, value|
        next if ['0', '1'].include?(settings[name])
        settings[name] = value
      end
    end

    def store
      @redis_key_prefix = 'highrise:'
      @store ||= SupportBeeApp::Store.new(redis_key_prefix: @redis_key_prefix)
    end

    def store_note_id(ticket_id, note_id)
      store.set(ticket_note_association_key(ticket_id), note_id)
    end

    def get_note_id(ticket_id)
      store.get(ticket_note_association_key(ticket_id))
    end

    def ticket_note_association_key(ticket_id)
      "ticket_note:#{ticket_id}"
    end

    def create_comment(options)
      return true unless settings.associate_reply_with_comment.to_s == '1'

      ticket = payload.ticket
      return true unless note_id = get_note_id(ticket.id)

      setup_highrise
      body = options['header'] + payload.reply.content.html
      comment = Highrise::Comment.new(parent_id: note_id, body: body)
      comment.save
    end

    def agent_reply_header(reply)
      Mab::Builder.new do
        p do
          text "New Agent Reply by #{reply.replier.name}"
          br
          br
        end
      end.to_s
    end

    def customer_reply_header(reply)
      Mab::Builder.new do
        p do
          text "New Customer Reply by #{reply.replier.name}"
          br
          br
        end
      end.to_s
    end

    def person_info_html(person)
      html = ""
      html << "<b> #{person.name} </b><br/>" 
      html << "#{person.title} " if person.title
      html << "#{person.company_name}" if person.company_name
      html << "<br/>"
      html << person_link(person)
      html
    end

    def company_info_html(company)
      html = "Ticket added to <b>#{company.name}</b> - "
      html << company_link(company)
      html
    end

    def new_person_info_html(person)
      html = "Added <b> #{person.name} </b> to Highrise - " 
      html << person_link(person)
      html
    end

    def new_company_info_html(company)
      html = "Added <b> #{company.name} </b> to Highrise - "
      html << company_link(company)
      html
    end

    def generate_note_content(ticket)
      note = ""
      note << ticket.summary + "<br/>" if settings.return_ticket_content.to_s == '1'
      note << "<a href='https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}'>https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}</a>"
    end

    def person_link(person)
      "<a href='https://#{settings.subdomain}.highrisehq.com/people/#{person.id}'>View #{person.first_name}'s profile on Highrise</a>"
    end

    def company_link(company)
      "<a href='https://#{settings.subdomain}.highrisehq.com/companies/#{company.id}'>View #{company.name} on Highrise</a>"
    end
  end
end

