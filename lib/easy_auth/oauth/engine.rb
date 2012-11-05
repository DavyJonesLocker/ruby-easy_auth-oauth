module EasyAuth::Oauth
  class Engine < ::Rails::Engine
    isolate_namespace EasyAuth::Oauth

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end
end
