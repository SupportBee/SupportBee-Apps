require 'spec_helper'
require 'yaml'

describe Insightly do
  let(:core_request) { YAML.load_file('spec/fixtures/insightly/core_request.yml')}

  describe "create note for customer" do
    it "sends correct data to the expected urls" do
      VCR.use_cassette 'insightly/api_response' do
        response = post "/insightly/action/button", core_request.to_json
        response.status.should eq 200
      end
    end
  end
end
