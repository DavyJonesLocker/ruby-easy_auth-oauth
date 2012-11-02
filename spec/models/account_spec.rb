require 'spec_helper'

describe EasyAuth::OAuth1::Models::Account do
  describe 'o_auth_identities relationship' do
    before do
      class OtherIdentity < EasyAuth::Identity; end
      class OAuth1IdentityA < EasyAuth::Identities::OAuth1::Base; end
      class OAuth1IdentityB < EasyAuth::Identities::OAuth1::Base; end

      @user = create(:user)
      @other_identity = OtherIdentity.create(:account => @user)
      @o_auth1_identity_a = OAuth1IdentityA.create(:account => @user)
      @o_auth1_identity_b = OAuth1IdentityB.create(:account => @user)
    end
    after do
      Object.send(:remove_const, :OtherIdentity)
      Object.send(:remove_const, :OAuth1IdentityA)
      Object.send(:remove_const, :OAuth1IdentityB)
    end

    it 'only returns OAuth identities' do
      @user.o_auth1_identities.should_not include(@other_identity)
      @user.o_auth1_identities.should     include(@o_auth1_identity_a)
      @user.o_auth1_identities.should     include(@o_auth1_identity_b)
    end
  end
end
