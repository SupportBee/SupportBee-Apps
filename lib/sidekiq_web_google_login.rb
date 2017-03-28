class SidekiqWebGoogleLogin
  def self.use
    google_client_id = APP_CONFIG["sidekiq_web_google_login"]["google_oauth2"][0]
    google_client_secret = APP_CONFIG["sidekiq_web_google_login"]["google_oauth2"][1]
    sidekiq_web_session_options = {
      :key => "ap_sidekiq_web_session",
      :domain => APP_CONFIG["sidekiq_web_google_login"]["session_domain"],
      :path => "/sidekiq",
      :expire_after => 24 * 60 * 60,
      :secret => APP_CONFIG["sidekiq_web_google_login"]["session_secret"]
    }

    Sidekiq::Web.use OmniAuth::Builder do
      provider :google_oauth2, google_client_id, google_client_secret
    end
    Sidekiq::Web.set :sessions, sidekiq_web_session_options
    Sidekiq::Web.register(SidekiqWebGoogleLogin)
  end

  def self.registered(sidekiq_web)
    sidekiq_web.before do
      next if session[:logged_in]
      next if request.path_info.start_with?("/auth/google_oauth2")

      if Sinatra::Request.new(request.env).accept.include?("text/html")
        redirect "/sidekiq/auth/google_oauth2"
      else
        halt(403)
      end
    end

    sidekiq_web.get "/auth/google_oauth2/callback" do
      auth = request.env['omniauth.auth']
      is_supportbee_employee = auth["info"]["email"].end_with?("@supportbee.com")

      if is_supportbee_employee
        session[:logged_in] = true
        redirect "/sidekiq"
      else
        halt(403)
      end
    end
  end
end
