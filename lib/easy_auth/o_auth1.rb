require 'easy_auth'
require 'easy_auth/o_auth1/engine'
require 'easy_auth/o_auth1/version'

module EasyAuth

  module OAuth1
    extend ActiveSupport::Autoload
    autoload :Controllers
    autoload :Models
    autoload :Routes
  end

  module Models
    module Account
      include EasyAuth::OAuth1::Models::Account
    end

    module Identities
      autoload :OAuth1
    end
  end

  module Controllers::Sessions
    include EasyAuth::OAuth1::Controllers::Sessions
  end

  def self.o_auth1_identity_model(params)
    method_name = "o_auth1_#{params[:provider]}_identity_model"
    camelcased_provider_name = params[:provider].to_s.camelcase
    if respond_to?(method_name)
      send(method_name, params)
    elsif eval("defined?(Identities::OAuth1::#{camelcased_provider_name})")
      eval("Identities::OAuth1::#{camelcased_provider_name}")
    else
      camelcased_provider_name.constantize
    end
  end

  class << self
    attr_accessor :o_auth1
  end

  self.o_auth1 = {}

  def self.o_auth1_client(provider, client_id, secret, scope = '')
    o_auth1[provider] = OpenStruct.new :client_id => client_id, :secret => secret, :scope => scope || ''
  end
end

ActionDispatch::Routing::Mapper.send(:include, EasyAuth::OAuth1::Routes)
