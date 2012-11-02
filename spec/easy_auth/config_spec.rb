require 'spec_helper'

describe 'Config' do
  before do
    EasyAuth.config do |c|
      c.o_auth1_client :twitter, 'client_id', 'secret', 'scope'
    end
  end

  it 'sets the value to the class instance variable' do
    EasyAuth.o_auth1[:twitter].client_id.should eq 'client_id'
    EasyAuth.o_auth1[:twitter].secret.should    eq 'secret'
    EasyAuth.o_auth1[:twitter].scope.should     eq 'scope'
  end
end
