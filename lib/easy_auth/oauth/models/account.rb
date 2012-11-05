module EasyAuth::Oauth::Models::Account
  extend ActiveSupport::Concern

  included do
    has_many :oauth_identities, :class_name => 'Identities::Oauth::Base', :foreign_key => :account_id
  end
end
