require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :request do
  let(:version) { '/api/v1' }
  let(:user_password) { Faker::Number.number(10) }
  let!(:user) { create(:user, password: user_password) }

  describe "(create) POST /api/v1/auth" do
    let(:valid_params) {
      {
        email: user.email,
        password: user_password
      }
    }

    context 'when the request is valid' do
      before { post "#{version}/auth", params: valid_params }

      it 'returns status code :ok' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the request is invalid' do
      before { post "#{version}/auth", params: {email: user.email, password: '123456'} }

      it 'returns status code :unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when email not found' do
      before { post "#{version}/auth", params: {email: 'fake@email.com', password: '123456'} }

      it 'returns status code :not_found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '(destroy) DELETE /api/v1/auth/token' do
    context 'when the request is valid' do
      before { delete "#{version}/auth/token", headers: {'Authorization' => "Token #{user.authentication_token}"} }

      it 'returns status code :ok' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the request is invalid' do
      before { delete "#{version}/auth/token", headers: {'Authorization' => 'Token 123'} }

      it 'returns status code :unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # describe '(webapp_facebook) POST /api/v1/auth/webapp/facebook' do
  #   let(:valid_params) {
  #     {
  #       code: 'AQCQckpfOYAQehhCLjU3Fn6wvXQWpNFMCJ99TUHPW_IiFUapOCjs8AVHffThNgA2JWjFnN-weSE-rkdABcrwJRCAGgcUhdsSPB5McZKywmbBHvw5FKjCrcpeRIVyKcVeOy-iBkegHJI4YDn3eMV9QOG8j1sh46LwB8M3WkjXNDtfjIlb5HlZvKKcm7tEOk1Et6ELENeOEpQ1Slicza10JRxSyBVlNDKm-CGHdE_nUQwLBSZr1ukQ-lMSiPGycSPa2_Z2a-GJ4cYV78rF2t0DVZrc-0IJK_L9KJp82WAL8mm0JNw1wVIXK6P7jyKdMztvBMS4sxHmZYhNjXAvs3P23o38',
  #       redirectUri: 'https://lifestak-messenger.herokuapp.com/'
  #     }
  #   }

  #   before { post "#{version}/auth/webapp/facebook", params: valid_params }

  #   it 'returns status code :ok' do
  #     expect(response).to have_http_status(:ok)
  #   end
  # end

  # describe '(mobile) POST /api/v1/auth/mobile/:provider' do
  #   let(:valid_params) {
  #     {
  #       token: '...',
  #       redirectUri: 'https://lifestak-messenger.herokuapp.com/'
  #     }
  #   }

  #   before { post "#{version}/auth/mobile/facebook", params: valid_params }

  #   it 'returns status code :ok' do
  #     expect(response).to have_http_status(:ok)
  #   end
  # end
end
