module Github 
  module ActionHandler
    def button
      ticket = payload.tickets.first
      begin
        response = create_issue(payload.overlay.title, payload.overlay.description, payload.overlay.projects_select)
        html = comment_html(response)
        comment_on_ticket(ticket, html)
      rescue Exception => e
        return [500, e.message]
      end
      [200, "Ticket sent to Github Issues"]
    end
  end
end

module Github
  require 'json'

  class Base < SupportBeeApp::Base
    oauth  :github, :required => true, :oauth_options => {:scope => "user,repo,gist"}

    def validate
      #errors[:flash] = ["Please fill in all the required fields"] if settings.owner.blank? or settings.repo.blank?
      #errors.empty? ? true : false
      true
    end
    
    def projects
      [200, fetch_projects]
    end
    
    def orgs
      [200, fetch_orgs]
    end

    # TODO: Move to a gem
    def api_url(resource = "", params = {})
      url = URI("https://api.github.com/#{resource}")
      url.query = to_query(params.merge(default_api_params))

      url.to_s
    end

    private

    def fetch_orgs
      response = github_get(orgs_url)
      response.body.to_json
    end
    
    def fetch_projects
      response = github_get(projects_url)
      response.body.to_json
    end
    
    def github_get(url)
      response = http.get url do |req|
       req.headers['User-Agent'] = 'SupportBee'
      end
    end

    def orgs_url
      api_url('user/orgs')
    end

    def projects_url
      resource = if payload.overlay and org = payload.overlay.org
        "orgs/#{org}/repos"
      else
        'user/repos'
      end

      api_url(resource, per_page: 200)
    end

    def token
      token = settings.oauth_token || settings.token
    end
    
    def create_issue(issue_title, description, repo)
      response = http_post "https://api.github.com/repos/#{repo}/issues?access_token=#{token}" do |req|
        req.body = {:title => issue_title, :body => description, :labels => ['supportbee']}.to_json
      end
    end

    def comment_html(response)
      "Github Issue created!\n <a href=#{response.body['html_url']}>#{response.body['title']}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

    def default_api_params
      { access_token: token }
    end

    def to_query(query_params)
      query_params.reduce("") do |query, (k, v)|
        query + "#{k}=#{v}&" # Not url encoding params for now. Just move to a gem.
      end.chop
    end
  end
end
