module EasyAuth::OAuth1::Routes
  def easy_auth_o_auth1_routes
    get  '/sign_in/o_auth1/:provider'          => 'sessions#new',    :as => :o_auth1_sign_in,  :defaults => { :identity => :o_auth1 }
    get  '/sign_in/o_auth1/:provider/callback' => 'sessions#create', :as => :o_auth1_callback, :defaults => { :identity => :o_auth1 }
  end
end
