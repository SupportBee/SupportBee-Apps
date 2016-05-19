require 'spec_helper'
require 'yaml'

describe Webhooks do
  let(:ticket_created) { YAML.load_file('spec/fixtures/webhooks/ticket_created.yml')}

  describe "create to-do item" do
    it "sends correct data to the expected urls" do
      flexmock(Faraday).should_receive(:post).with(ticket_created[:payload]).once
      response = post "/basecamp/action/button", ticket_created.to_json
    end
  end
end
