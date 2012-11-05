module EasyAuth::Oauth::Routes
  def easy_auth_oauth_routes
    get  '/sign_in/oauth/:provider'          => 'sessions#new',    :as => :oauth_sign_in,  :defaults => { :identity => :oauth }
    get  '/sign_in/oauth/:provider/callback' => 'sessions#create', :as => :oauth_callback, :defaults => { :identity => :oauth }
  end
end
