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

  def self.o_auth1_identity_model(controller)
    send("o_auth1_#{controller.params[:provider]}_identity_model", controller)
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
