require 'spec_helper'

describe EasyAuth::Oauth::Models::Account do
  describe 'o_auth_identities relationship' do
    before do
      class OtherIdentity < Identity; end
      class OauthIdentityA < Identities::Oauth::Base; end
      class OauthIdentityB < Identities::Oauth::Base; end

      @user = create(:user)
      @other_identity = OtherIdentity.create(:account => @user)
      @oauth_identity_a = OauthIdentityA.create(:account => @user)
      @oauth_identity_b = OauthIdentityB.create(:account => @user)
    end
    after do
      Object.send(:remove_const, :OtherIdentity)
      Object.send(:remove_const, :OauthIdentityA)
      Object.send(:remove_const, :OauthIdentityB)
    end

    it 'only returns OAuth identities' do
      @user.oauth_identities.should_not include(@other_identity)
      @user.oauth_identities.should     include(@oauth_identity_a)
      @user.oauth_identities.should     include(@oauth_identity_b)
    end
  end
end
