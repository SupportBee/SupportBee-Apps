require 'spec_helper'
require 'yaml'

describe ExtractSenderFromEmail do
  let(:ticket_without_email) { YAML.load_file('spec/fixtures/extract_sender_from_email/ticket_without_email.yml') }
  let(:ticket_with_email) { YAML.load_file('spec/fixtures/extract_sender_from_email/ticket_with_email.yml') }
  let(:url) { "#{ExtractSenderFromEmail::Base.slug}/event/ticket.created" }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe "when customer creates a ticket" do
    context "when there is no email in the body" do
      it 'should not ask core app to change receiver' do
        response = post(url, ticket_without_email.to_json, headers)
        response.status.should eq 204
      end
    end

    context "when there is an email in the body" do
      it 'should ask core app to change receiver' do
        VCR.use_cassette 'extract_sender_from_email/api_response' do
          response = post(url, ticket_with_email.to_json, headers)
          response.status.should eq 204
        end
      end
    end
  end
end
