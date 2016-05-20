require 'spec_helper'
require 'yaml'

describe Webhook do
  let(:ticket_created) { YAML.load_file('spec/fixtures/webhook/ticket_created.yml')}
  let(:ticket_trashed) { YAML.load_file('spec/fixtures/webhook/ticket_trashed.yml')}

  let(:url1) { "http://example1.com" }
  let(:url2) { "http://example2.com" }

  describe "work as proxy for all events" do
    context ".api_hash" do
      it "should return a list containing 'all.events'" do
        Webhook::Base.api_hash['events'].should == ['all.events']
      end
    end
  end

  describe "ticket created" do
    it "sends correct data to the expected urls" do
      request_params = {body: ticket_created[:payload]}
      response_params = {status: 200, body: "", headers: {'Content-Type' => 'application/json'}}

      stub_request(:post, url1).with(request_params).to_return(response_params)
      stub_request(:post, url2).with(request_params).to_return(response_params)

      response = post "/webhook/event/ticket.created", ticket_created.to_json
      response.status.should == 204
    end
  end

  describe "ticket trashed" do
    it "sends correct data to the expected urls" do
      request_params = {body: ticket_trashed[:payload]}
      response_params = {status: 200, body: "", headers: {'Content-Type' => 'application/json'}}

      stub_request(:post, url1).with(request_params).to_return(response_params)

      response = post "/webhook/event/ticket.trashed", ticket_trashed.to_json
      response.status.should == 204
    end
  end
end
