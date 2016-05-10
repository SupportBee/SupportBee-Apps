require 'spec_helper'
require 'yaml'

describe Basecamp do
  let(:todo_item) { YAML.load_file('spec/fixtures/basecamp/todo_item.yml')}

  describe "create to-do item" do
    it "sends correct data to the expected urls" do
      VCR.use_cassette 'basecamp/api_response' do
        response = post "/basecamp/action/button", todo_item.to_json
        response.status.should eq 200
      end
    end
  end
end
