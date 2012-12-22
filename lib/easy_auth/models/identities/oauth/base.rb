require 'oauth'

module EasyAuth::Models::Identities::Oauth::Base
  def self.included(base)
    base.class_eval do
      serialize :token, Hash
      validates :uid, :presence => true
      extend ClassMethods
    end
  end

  module ClassMethods
    def authenticate(controller)
      if controller.params[:oauth_token].present? && controller.params[:oauth_verifier].present?
        oauth_token         = controller.params[:oauth_token]
        oauth_verifier      = controller.params[:oauth_verifier]
        access_token_secret = controller.session.delete('access_token_secret')
        request_token       = OAuth::RequestToken.new(client, oauth_token, access_token_secret)
        access_token        = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        uid                 = retrieve_uid(access_token)
        identity            = self.find_or_initialize_by_uid uid.to_s
        identity.token      = {:token => access_token.token, :secret => access_token.secret}

        if controller.current_account
          if identity.account
            if identity.account != controller.current_account
              controller.flash[:error] = 'Error!'
              return nil
            end
          else
            identity.account = controller.current_account
          end
        else
          unless identity.account
            identity.account = EasyAuth.account_model.create!(account_attributes(access_token.params))
          end
        end

        identity.save!
        identity
      end
    end

    def account_attributes(user_info)
      setters = EasyAuth.account_model.instance_methods.grep(/=$/) - [:id=]
      account_attributes_map.inject({}) do |hash, kv|
        if setters.include?("#{kv[0]}=".to_sym)
          hash[kv[0]] = user_info[kv[1]]
        end

        hash
      end
    end

    def account_attributes_map
      { :email => 'email' }
    end

    def new_session(controller)
      controller.redirect_to authenticate_url(controller.oauth_callback_url(:provider => provider), controller.session)
    end

    def get_access_token(identity)
      ::OAuth::AccessToken.new client, identity.token[:token], identity.token[:secret]
    end

    private

    def token_options(callback_url)
      { :redirect_uri => callback_url }
    end

    def client_options
      { :site => site_url, :authorize_path => authorize_path }
    end

    def retrieve_uid(token)
      raise NotImplementedError
    end

    def client
      @client ||= ::OAuth::Consumer.new(client_id, secret, client_options)
    end

    def authenticate_url(callback_url, session)
      request_token = client.get_request_token(:oauth_callback => callback_url)
      session['access_token_secret'] = request_token.secret
      request_token.authorize_url(:oauth_callback => callback_url)
    end

    def authorize_path
      raise NotImplementedError
    end

    def site_url
      raise NotImplementedError
    end

    def client_id
      settings.client_id
    end

    def secret
      settings.secret
    end

    def settings
      EasyAuth.oauth[provider]
    end

    def provider
      self.to_s.split('::').last.underscore.to_sym
    end
  end

  def get_access_token
    self.class.get_access_token self
  end
end
