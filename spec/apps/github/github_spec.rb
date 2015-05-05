require 'spec_helper'

describe "#api_url" do
  it "constructs api url with params" do
    data = {
      auth: { subdomain: 'muziboo' },
      settings: { oauth_token: 'access_token' }
    }
    github = Github::Base.new(data)

    resource = "user/orgs"
    github.api_url(resource).should == "https://api.github.com/user/orgs?access_token=access_token"
    resource = "user/repos"
    github.api_url(resource, per_page: 100).should == "https://api.github.com/user/repos?per_page=100&access_token=access_token"
  end
end
