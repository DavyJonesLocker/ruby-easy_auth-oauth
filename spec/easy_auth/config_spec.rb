require 'spec_helper'

describe 'Config' do
  before do
    EasyAuth.config do |c|
      c.oauth_client :twitter, 'client_id', 'secret'
    end
  end

  it 'sets the value to the class instance variable' do
    EasyAuth.oauth[:twitter].client_id.should eq 'client_id'
    EasyAuth.oauth[:twitter].secret.should    eq 'secret'
  end
end
