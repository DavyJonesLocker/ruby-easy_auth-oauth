module EasyAuth::OAuth1::Models::Account
  extend ActiveSupport::Concern

  included do
    has_many :o_auth1_identities, :class_name => 'EasyAuth::Identities::OAuth1::Base', :foreign_key => :account_id
  end
end
