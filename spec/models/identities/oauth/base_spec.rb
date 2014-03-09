require 'spec_helper'

class BaseTestController < ActionController::Base
  def initialize(request = OpenStruct.new(parameters: {}))
    super()
    @_request = request
  end

  def current_account
    nil
  end

  def oauth2_callback_url(options = {})
    ''
  end
end

class SessionsController < BaseTestController
  include EasyAuth::Controllers::Sessions

  def user_url(user)
    "/users/#{user.id}"
  end

  def after_failed_sign_in
    render text: ''
  end
end

class UsersController < BaseTestController
  def create
    User.create(user_params)
    redirect_to '/'
  end

  private

  def user_params
    params.require(:user).permit!
  end
end

describe EasyAuth::Models::Identities::Oauth::Base do
  before(:all) do
    class TestIdentity < Identity
      include EasyAuth::Models::Identities::Oauth::Base

      private

      def self.retrieve_uid(user_attributes)
        user_attributes[:user_id]
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


  it { should     have_valid(:uid).when('123') }
  it { should_not have_valid(:uid).when(nil, '') }

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
      let(:controller) { SessionsController.new }

      it 'returns nil when :oauth_token param is missing' do
        controller.params[:oauth_verifyer] = 'test'
        TestIdentity.authenticate(controller).should be_nil
      end

      it 'returns nil when :oauth_verifyer param is missing' do
        controller.params[:oauth_token] = 'test'
        TestIdentity.authenticate(controller).should be_nil
      end
    end

    context 'success states' do
      let(:run_controller) { SessionsController.action(:create).call(Rack::MockRequest.env_for("?#{{:oauth_token => '123', :oauth_verifier => 'test', identity: 'oauth', provider: 'test_identity'}.to_param}")) }
      let(:email) { FactoryGirl.generate(:email) }

      before do
        access_token  = OpenStruct.new(:token => '123', :secret => 'abc', :params => {:email => 'test@example.com', :user_id => '123'})
        OAuth::RequestToken.any_instance.stubs(:get_access_token).returns(access_token)
      end

      context 'identity does not exist' do
        context 'linking to an existing account' do
          before do
            @user = create(:user)
            SessionsController.any_instance.stubs(:current_account).returns(@user)
          end

          it 'returns an identity' do
            run_controller
            @user.identities.first.should be_instance_of(TestIdentity)
          end

          it 'creates a new identity' do
            expect {
              run_controller
            }.to change { TestIdentity.count }.by(1)
          end
        end

        context 'creating a new account' do
          it 'creates a new account' do
            expect {
              run_controller
            }.to change { User.count }.by(1)
          end

          it 'creates a new identity' do
            expect {
              run_controller
            }.to change { TestIdentity.count }.by(1)
          end
        end
      end

      context 'identity already exists' do
        before do
          @test_identity = TestIdentity.create(:uid => '123', :token => {:token => '123', :secret => 'abc'})
        end

        context 'linking to an existing account' do
          before do
            @user = create(:user, :email => email)
            SessionsController.any_instance.stubs(:current_account).returns(@user)
          end

          it 'returns an identity' do
            run_controller
            @user.identities.first.should eq @test_identity
          end

          it 'does not create a new identity' do
            expect {
              run_controller
            }.to_not change { TestIdentity.count }
          end

          context 'identity account and current account mismatch' do
            before do
              @test_identity.update_attribute(:account, create(:user))
              run_controller
            end

            it 'does not overwrite the account' do
              @test_identity.account.should_not eq @user
            end

            it 'sets an error flash' do
              pending
            end
          end
        end
      end
    end
  end
end
