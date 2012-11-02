module EasyAuth::OAuth1
  class Engine < ::Rails::Engine
    isolate_namespace EasyAuth::OAuth1

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end
end
