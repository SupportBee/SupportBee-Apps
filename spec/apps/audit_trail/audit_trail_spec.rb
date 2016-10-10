require 'spec_helper'

describe AuditTrail do
  let(:api_token) { 'my_api_token' }
  let(:response_headers) do
    {
      'Content-Type' => 'application/json'
    }
  end

  before(:each) do
    # Stub refresh ticket request
    response_body = {
      'ticket' => {
        'id' => 1
      }
    }.to_json
    stub_request(:get, "http://muziboo.lvh.me:3000/tickets/1?auth_token=my_api_token").to_return(status: 200, body: response_body, headers: response_headers)
  end

  describe '#ticket_assigned_to_agent' do
    let(:event_name) { 'ticket.assigned.to.user' }

    it 'adds a comment to the ticket' do
      # Stub create comment request
      url = "http://muziboo.lvh.me:3000/tickets/1/comments?auth_token=my_api_token"
      request_body_hash = {
        'comment' => {
          'content_attributes' => {
            'body_html' => "Assigned to Dexter (dexter@labs.com) by Dee Dee (deedee@example.com) at 12:00 pm, 01/18/15 UTC"
          }
        }
      }
      response_body = {
        'comment' => {
          'content' => {
            'text' => 'Everything is awesome',
            'html' => '<p>Everything is awesome!</p>'
          },
          'attachment_ids' => []
        }
      }.to_json
      stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)

      request_body = {
        'payload' => {
          'payload' => {
            'action_type' => event_name,
            'company' => {
              'subdomain' => 'muziboo',
              'name' => 'Muziboo Music'
            },
            'ticket' => {
              'id' => 1
            },
            # Assigner
            'agent' => {
              'id' => 2,
              'name' => 'Dee Dee',
              'email' => 'deedee@labs.com'
            },
            'user_assignment' => {
              'id' => 1,
              'assignee' => {
                'user' => {
                  'id' => 1,
                  'name' => 'Dexter',
                  'email' => 'dexter@labs.com'
                }
              }
            }
          }
        },
        'data' => {
          'auth' => {
            'auth_token' => 'my_api_token',
            'subdomain' => 'muziboo'
          }
        }
      }.to_json
      response = post "#{AuditTrail::Base.slug}/event/#{event_name}", request_body, 'CONTENT_TYPE' => 'application/json'

      # This is a brittle test but its better than not having any test
      response.status.should == 204
    end
  end

  describe '#ticket_assigned_to_team' do
    let(:event_name) { 'ticket.assigned.to.team' }

    it 'adds a comment to the ticket' do
      # Stub create comment request
      url = "http://muziboo.lvh.me:3000/tickets/1/comments?auth_token=#{api_token}"
      response_body = {
        'comment' => {
          'content' => {
            'text' => 'Everything is awesome',
            'html' => '<p>Everything is awesome!</p>'
          },
          'attachment_ids' => []
        }
      }.to_json
      stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)

      request_body = {
        'payload' => {
          'payload' => {
            'action_type' => event_name,
            'company' => {
              'subdomain' => 'muziboo',
              'name' => 'Muziboo Music'
            },
            'ticket' => {
              'id' => 1,
              'group' => {
                'id' => 1,
                'name' => 'Designers'
              }
            },
            # Sender
            'agent' => {
              'id' => 2,
              'name' => 'Dee Dee',
              'email' => 'deedee@labs.com'
            },
            'team_assignment' => {
              'id' => 10,
              'assignee' => {
                'team' => {
                  'id' => 11,
                  'name' => 'Dexter Team'
                }
              }
            }
          }
        },
        'data' => {
          'auth' => {
            'auth_token' => 'my_api_token',
            'subdomain' => 'muziboo'
          }
        }
      }.to_json
      response = post "#{AuditTrail::Base.slug}/event/#{event_name}", request_body, 'CONTENT_TYPE' => 'application/json'

      response.status.should == 204
    end
  end

  describe '#ticket_unassigned_from_agent' do
    let(:event_name) { 'ticket.unassigned.from.user' }

    it 'adds a comment to the ticket' do
      # Stub create comment request
      url = "http://muziboo.lvh.me:3000/tickets/1/comments?auth_token=#{api_token}"
      response_body = {
        'comment' => {
          'content' => {
            'text' => 'Everything is awesome',
            'html' => '<p>Everything is awesome!</p>'
          },
          'attachment_ids' => []
        }
      }.to_json
      stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)

      request_body = {
        'payload' => {
          'payload' => {
            'action_type' => event_name,
            'company' => {
              'subdomain' => 'muziboo',
              'name' => 'Muziboo Music'
            },
            'ticket' => {
              'id' => 1
            }
          }
        },
        'data' => {
          'auth' => {
            'auth_token' => 'my_api_token',
            'subdomain' => 'muziboo'
          }
        }
      }.to_json
      response = post "#{AuditTrail::Base.slug}/event/#{event_name}", request_body, 'CONTENT_TYPE' => 'application/json'

      response.status.should == 204
    end
  end

  describe '#ticket_unassigned_from_team' do
    let(:event_name) { 'ticket.unassigned.from.team' }

    it 'adds a comment to the ticket' do
      # Stub create comment request
      url = "http://muziboo.lvh.me:3000/tickets/1/comments?auth_token=#{api_token}"
      response_body = {
        'comment' => {
          'content' => {
            'text' => 'Everything is awesome',
            'html' => '<p>Everything is awesome!</p>'
          },
          'attachment_ids' => []
        }
      }.to_json
      stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)

      request_body = {
        'payload' => {
          'payload' => {
            'action_type' => event_name,
            'company' => {
              'subdomain' => 'muziboo',
              'name' => 'Muziboo Music'
            },
            'ticket' => {
              'id' => 1
            }
          }
        },
        'data' => {
          'auth' => {
            'auth_token' => 'my_api_token',
            'subdomain' => 'muziboo'
          }
        }
      }.to_json
      response = post "#{AuditTrail::Base.slug}/event/#{event_name}", request_body, 'CONTENT_TYPE' => 'application/json'

      response.status.should == 204
    end
  end
end
