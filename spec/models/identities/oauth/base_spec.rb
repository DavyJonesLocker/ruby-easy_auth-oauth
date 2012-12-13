require 'spec_helper'

describe EasyAuth::Models::Identities::Oauth::Base do
  before(:all) do
    class TestIdentity < Identity
      include(EasyAuth::Models::Identities::Oauth::Base)

      private

      def self.retrieve_username(token)
        token.params[:user_id]
      end
    end
  end

  before { TestIdentity.stubs(:client).returns(client) }

  after(:all) do
    Object.send(:remove_const, :TestIdentity)
  end

  subject { TestIdentity.new }

  let(:client)   { OAuth::Consumer.new('client_id', 'secret', :site => 'http://example.com', :authorize_url => '/auth', :token_url => '/token' ) }
  let(:identity) { TestIdentity.new :token => { :token => 'token', :secret => 'token-secret' } }


  it { should     have_valid(:username).when('123') }
  it { should_not have_valid(:username).when(nil, '') }

  context 'access tokens' do
    describe '.get_access_token' do
      it 'returns an OAuth::AccessToken' do
        access_token = TestIdentity.get_access_token identity
        access_token.class.should eq OAuth::AccessToken
      end

      it "sets the token's consumer to the class's client" do
        access_token = TestIdentity.get_access_token identity
        access_token.consumer.should eq client
      end

      it "sets the token's token to the token passed in" do
        access_token = TestIdentity.get_access_token identity
        access_token.token.should eq 'token'
      end

      it "sets the token's secret to the secret passed in" do
        access_token = TestIdentity.get_access_token identity
        access_token.secret.should eq 'token-secret'
      end
    end

    describe '#get_access_token' do
      it 'returns an OAuth::AccessToken' do
        access_token = identity.get_access_token
        access_token.class.should eq OAuth::AccessToken
      end

      it "sets the token's consumer to the class's client" do
        access_token = identity.get_access_token
        access_token.consumer.should eq client
      end

      it "sets the token's token to the token passed in" do
        access_token = identity.get_access_token
        access_token.token.should eq 'token'
      end

      it "sets the token's secret to the secret passed in" do
        access_token = identity.get_access_token
        access_token.secret.should eq 'token-secret'
      end
    end
  end

  describe '#authenticate' do
    context 'failure states' do
      let(:controller) { OpenStruct.new(:params => {}, :session => {}) }

      it 'returns nil when :oauth_token param is missing' do
        TestIdentity.authenticate(controller).should be_nil
      end

      it 'returns nil when :oauth_verifier param is missing' do
        controller.params[:oauth_token]  = '123'
        TestIdentity.authenticate(controller).should be_nil
      end

      context 'with invalid account' do
        let(:controller) { OpenStruct.new(:params => { :oauth_token => '123', :oauth_verifier => 'test' }, :session => {}) }
        let(:identity) { TestIdentity.authenticate(controller) }
        before do
          controller.stubs(:oauth_callback_url).returns('')
          controller.stubs(:curent_account).returns(nil)
          access_token  = OpenStruct.new(:token => '123', :secret => 'abc', :params => {:email => 'test@example.com'})
          OAuth::RequestToken.any_instance.stubs(:get_access_token).returns(access_token)
          User.any_instance.stubs(:perform_validations).returns(false)
        end

        it 'raises ActiveRecord::RecordInvalid' do
          expect {
            identity
          }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'success states' do
      let(:controller) { OpenStruct.new(:params => { :oauth_token => '123', :oauth_verifier => 'test' }, :session => {}) }
      let(:identity) { TestIdentity.authenticate(controller) }
      before do
        controller.stubs(:oauth_callback_url).returns('')
        access_token  = OpenStruct.new(:token => '123', :secret => 'abc', :params => {:email => 'test@example.com', :user_id => '123'})
        OAuth::RequestToken.any_instance.stubs(:get_access_token).returns(access_token)
      end

      context 'identity does not exist' do
        context 'linking to an existing account' do
          before do
            @user = create(:user)
            controller.stubs(:current_account).returns(@user)
          end

          it 'returns an identity' do
            identity.should be_instance_of(TestIdentity)
          end

          it 'links to the account' do
            identity.account.should eq @user
          end
        end

        context 'creating a new account' do
          before do
            controller.stubs(:curent_account).returns(nil)
          end

          it 'returns an identity' do
            identity.should be_instance_of(TestIdentity)
          end

          it 'creates a new account' do
            expect {
              identity
            }.to change { User.count }.by(1)
          end
        end
      end

      context 'identity already exists' do
        before do
          TestIdentity.create(:username => '123', :token => {:token => '123', :secret => 'abc'})
        end

        context 'linking to an existing account' do
          before do
            @user = create(:user)
            controller.stubs(:current_account).returns(@user)
          end

          it 'returns an identity' do
            identity.should be_instance_of(TestIdentity)
          end

          it 'links to the account' do
            identity.account.should eq @user
          end

          it 'does not create a new identity' do
            expect {
              identity
            }.to_not change { TestIdentity.count }
          end
        end

        context 'creating a new account' do
          let(:identity) { TestIdentity.authenticate(controller) }
          before do
            controller.stubs(:curent_account).returns(nil)
          end

          it 'returns an identity' do
            identity.should be_instance_of(TestIdentity)
          end

          it 'creates a new account' do
            expect {
              identity
            }.to change { User.count }.by(1)
          end

          it 'does not create a new identity' do
            expect {
              identity
            }.to_not change { TestIdentity.count }
          end
        end
      end
    end
  end
end
