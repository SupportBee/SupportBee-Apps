require 'spec_helper'

describe AuditTrail do
  describe '#ticket_assigned_to_agent' do
    let(:time_now) { Time.utc(2015, 'Jan', 18, 12) }

    it 'adds a comment to the ticket' do
      skip 'have to fix failing webmock expectations'

      url = "http://muziboo.lvh.me:3000/tickets/1/comments?auth_token=my_api_token"
      create_comment_url = url
      request_body_hash = {
        'comment' => {
          'content_attributes' => {
            'body_html' => "Assigned to Dexter (dexter@labs.com) by Dee Dee (deedee@example.com) at 12:00 pm, 01/18/15 UTC"
          }
        }
      }
      create_comment_request_body_hash = request_body_hash
      response_body = {
        'comment' => {
          'content' => {
            'text' => 'Everything is awesome',
            'html' => '<p>Everything is awesome!</p>'
          },
          'attachment_ids' => []
        }
      }.to_json
      create_comment_response_body = response_body
      response_headers = {
        'Content-Type' => 'application/json'
      }
      create_comment_request = stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)
      response_body = {
        'ticket' => {
          'id' => 1
        }
      }.to_json
      stub_request(:get, "http://muziboo.lvh.me:3000/tickets/1?auth_token=my_api_token").to_return(status: 200, body: response_body, headers: response_headers)

      request_body = {
        'payload' => {
          'payload' => {
            'action_type' => 'ticket.assigned.to.agent',
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
            'assignment' => {
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
      response = nil
      Timecop.freeze(time_now) do
        response = post "#{AuditTrail::Base.slug}/event/ticket.assigned.to.agent", request_body, 'CONTENT_TYPE' => 'application/json'
      end

      response.status.should == 204
      # create_comment_request.should have_been_made.once
      # WebMock.should have_requested(:post, url).with(body: create_comment_request_body_hash).once
    end
  end

  describe '#ticket_sent_to_group' do
    let(:api_token) { 'my_api_token' }
    let(:event_name) { 'ticket.sent.to.group' } 

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
      response_headers = {
        'Content-Type' => 'application/json'
      }
      stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)

      # Stub refresh ticket request
      url = "http://muziboo.lvh.me:3000/tickets/1?auth_token=#{api_token}"
      response_body = {
        'ticket' => {
          'id' => 1
        }
      }.to_json
      stub_request(:get, url).to_return(status: 200, body: response_body, headers: response_headers)

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

  describe '#ticket_removed_from_group' do
    let(:api_token) { 'my_api_token' }
    let(:event_name) { 'ticket.removed.from.group' } 

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
      response_headers = {
        'Content-Type' => 'application/json'
      }
      stub_request(:post, url).to_return(status: 200, body: response_body, headers: response_headers)

      # Stub refresh ticket request
      url = "http://muziboo.lvh.me:3000/tickets/1?auth_token=#{api_token}"
      response_body = {
        'ticket' => {
          'id' => 1
        }
      }.to_json
      stub_request(:get, url).to_return(status: 200, body: response_body, headers: response_headers)

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

      # This is a brittle test but its better than not having any test
      response.status.should == 204
    end
  end
end
