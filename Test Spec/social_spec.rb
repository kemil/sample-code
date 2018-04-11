require 'rails_helper'

RSpec.describe Api::V1::SocialController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:provider) { create(:provider, user_id: user.id) }

  # describe '(mobile) POST /api/v1/social/mobile' do
  #   let(:valid_params) {
  #     {
  #       token: '...',
  #       redirectUri: 'https://lifestak-messenger.herokuapp.com/',
  #       provider: 'facebook'
  #     }
  #   }

  #   before { post "#{version}/social/mobile", headers: token_auth, params: valid_params }

  #   it 'returns status code :created' do
  #     expect(response).to have_http_status(:created)
  #   end
  # end

  describe '(destroy) DELETE /api/v1/social/:provider' do
    before { delete "#{version}/social/#{provider.name}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
