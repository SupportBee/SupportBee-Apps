require 'spec_helper'
require 'yaml'
require 'pry'

describe Basecamp do
  let(:todo_item) { YAML.load_file('spec/fixtures/basecamp/todo_item.yml')}
  let(:basecamp_headers) { YAML.load_file('spec/fixtures/basecamp/basecamp_headers.yml') }
  let(:create_todo_item_response) { YAML.load_file('spec/fixtures/basecamp/create_todo_item_response.yml') }
  let(:create_comment_response) { YAML.load_file('spec/fixtures/basecamp/create_comment_response.yml') }
  let(:comment) { YAML.load_file('spec/fixtures/supportbee/comment.yml') }

  describe "create to-do item" do
    it "sends correct data to the expected urls" do
      todos_url = 'https://basecamp.com/3385370/api/v1/projects/12176000/todolists/38438511/todos.json'
      comments_url = 'https://basecamp.com/3385370/api/v1/projects/12176000/todos/250867970/comments.json'
      ticket_url = 'http://test.https//supportbee.com:/tickets/2/comments?auth_token=AUTH_TOKEN'
      ticket_comment = "Basecamp todo created in the list <a href='https://basecamp.com/3385370/projects/12176000/todolists/38438511'>Todo item created</a>"

      stub_request(:post, todos_url)
        .with(:body => { content: "Ticket title" }.to_json, :headers => basecamp_headers)
        .to_return(:status => 201, :body => create_todo_item_response.to_json, :headers => {})

      stub_request(:post, comments_url)
        .with(:body => "{\"content\":\"ticket content\"}", :headers => basecamp_headers)
        .to_return(:status => 201, :body => create_comment_response.to_json, :headers => {})

      stub_request(:post, ticket_url)
        .with(
          :body => {"comment" => {"content_attributes" => {"body_html"=> ticket_comment}}},
          :headers => {
            'Accept'=>'application/json',
            'Content-Type'=>'application/x-www-form-urlencoded',
            'User-Agent'=>'Ruby'
        }).to_return(:status => 201, :body => {comments: [comment]}.to_json, :headers => {})

        stub_request(:get, "http://test.https//supportbee.com:/tickets/2?auth_token=AUTH_TOKEN")
          .with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'})
          .to_return(:status => 200, :body => "", :headers => {})

      response = post "/basecamp/action/button", todo_item.to_json
      response.status.should eq 200
    end
  end
end
