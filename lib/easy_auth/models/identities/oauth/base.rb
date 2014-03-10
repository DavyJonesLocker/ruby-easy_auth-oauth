require 'easy_auth-oauth_core'
require 'oauth'

module EasyAuth::Models::Identities::Oauth::Base
  extend ActiveSupport::Concern
  include EasyAuth::Models::Identities::OauthCore

  included do
    serialize :token, Hash
  end

  module ClassMethods
    def authenticate(controller)
      super(controller) do
        oauth_token         = controller.params[:oauth_token]
        oauth_verifier      = controller.params[:oauth_verifier]
        access_token_secret = controller.session.delete('access_token_secret')
        request_token       = OAuth::RequestToken.new(client, oauth_token, access_token_secret)
        token               = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        account_attributes     = get_account_attributes(token)
        identity            = self.find_or_initialize_by(uid: retrieve_uid(account_attributes))
        identity.token      = {:token => token.token, :secret => token.secret}

        [identity, account_attributes]
      end
    end

    def can_authenticate?(controller)
      controller.params[:oauth_token].present? && controller.params[:oauth_verifier].present?
    end

    def new_session(controller)
      controller.redirect_to authenticate_url(controller.oauth_callback_url(:provider => provider), controller.session)
    end

    def get_access_token(identity)
      ::OAuth::AccessToken.new client, identity.token[:token], identity.token[:secret]
    end

    def client_options
      { :site => site_url, :authorize_path => authorize_path }
    end

    def get_account_attributes(token)
      token.params
    end

    def version
      :oauth
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
  end
end
