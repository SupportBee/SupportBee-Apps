require 'spec_helper'
require 'yaml'

describe Webhook do
  let(:ticket_created) { YAML.load_file('spec/fixtures/webhook/ticket_created.yml')}
  let(:url1) { "http://example1.com" }
  let(:url2) { "http://example2.com" }

  describe "create to-do item" do
    it "sends correct data to the expected urls" do
      stub_request(:post, url1).to_return(status: 200, body: "", headers: {'Content-Type' => 'application/json'})
      stub_request(:post, url2).to_return(status: 200, body: "", headers: {'Content-Type' => 'application/json'})
      response = post "/webhook/event/ticket.created", ticket_created.to_json
      response.status.should == 204
    end
  end
end
