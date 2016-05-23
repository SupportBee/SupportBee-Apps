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

  describe "validate urls" do
    let(:validate_payload) { YAML.load_file('spec/fixtures/webhook/validate_payload.yml')}

    context "without empty input" do
      it "should be invalid" do
        validate_payload[:data]["settings"]["urls"] = ''
        response = post "/webhook/valid", validate_payload.to_json
        response.status.should == 400
        response.body.should == '{"errors":{"urls":"Cannot be blank"}}'
      end
    end

    context "with one url" do
      it "should be valid if url is valid" do
        VCR.use_cassette 'webhook/api_response' do
          validate_payload[:data]["settings"]["urls"] = 'http://example.com'
          response = post "/webhook/valid", validate_payload.to_json
          response.status.should == 200
        end
      end

      it "should be invalid if url is invalid" do
        VCR.use_cassette 'webhook/api_response' do
          validate_payload[:data]["settings"]["urls"] = 'crapyurl'
          response = post "/webhook/valid", validate_payload.to_json
          response.status.should == 400
          response.body.should == "{\"errors\":{\"urls\":\"Invalid URLs: crapyurl\"}}"
        end
      end
    end

    context "with two urls" do
      it "should be valid all urls are valid" do
        VCR.use_cassette 'webhook/api_response' do
          validate_payload[:data]["settings"]["urls"] = 'http://example.com, http://otherexample.com'
          response = post "/webhook/valid", validate_payload.to_json
          response.status.should == 200
        end
      end

      it "should be invalid if first url is invalid" do
        VCR.use_cassette 'webhook/api_response' do
          validate_payload[:data]["settings"]["urls"] = 'crapyurl1; http://otherexample.com'
          response = post "/webhook/valid", validate_payload.to_json
          response.status.should == 400
          response.body.should == "{\"errors\":{\"urls\":\"Invalid URLs: crapyurl1\"}}"
        end
      end

      it "should be invalid if second url is invalid" do
        VCR.use_cassette 'webhook/api_response' do
          validate_payload[:data]["settings"]["urls"] = 'http://example.com, crapyurl2'
          response = post "/webhook/valid", validate_payload.to_json
          response.status.should == 400
          response.body.should == "{\"errors\":{\"urls\":\"Invalid URLs: crapyurl2\"}}"
        end
      end

      it "should be invalid if all urls are invalid" do
        VCR.use_cassette 'webhook/api_response' do
          validate_payload[:data]["settings"]["urls"] = 'crapyurl1, crapyurl2'
          response = post "/webhook/valid", validate_payload.to_json
          response.status.should == 400
          response.body.should == "{\"errors\":{\"urls\":\"Invalid URLs: crapyurl1, crapyurl2\"}}"
        end
      end
    end
  end
end
