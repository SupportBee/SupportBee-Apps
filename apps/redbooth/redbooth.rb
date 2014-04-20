module Redbooth
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      return true
    end

    # Handle all events
    def all_events
      return true
    end
  end
end

module Redbooth
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Redbooth
  class Base < SupportBeeApp::Base

		oauth :redbooth,
			oauth_options: {
				expiration: :never,
				scope: 'read,write'
			}		

		string :username,
			required: true,
			label: 'Redbooth Username',
			hint: 'Username is required to identify your Redbooth account'

		string :password,
			required: true,
			label: 'Redbooth Password'
			hint: 'Password is required to authorize your Redbooth account'

    # Define Settings
    # string :name, :required => true, :hint => 'Tell me your name'
    # string :username, :required => true, :label => 'User Name'
    # password :password, :required => true
    # boolean :notify_me, :default => true, :label => 'Notify Me'

    # White list settings for logging
    # white_list :username, :password

    # Define public and private methods here which will be available
    # in the EventHandler and ActionHandler modules

		def task_list_id
		
	 	end

		private

		def base_url
			Pathname.new("https://redbooth.com/")
		end

		def base_api_url
			base_url.join('api', '1')
		end

		def task_lists_url
			base_api_url.join('task_lists')
		end

		def taks_list_id_url
			task_lists_url.join()
		end

		def redbooth_post(url, body)
			http.post "#{url.to_s}.json" do |req|
				req.headers['Content-Type'] = 'application/json'
				req.headers['Accept'] = 'application/json'
				req.body = body
		end

		def redbooth_get(url)
			response = http.get "#{url.to_s}.json" do |req|
				req.headers['Accept'] = 'application/json'
			end
		end

  end
end

