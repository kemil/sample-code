require 'rails_helper'

RSpec.describe Api::V1::PasswordController, type: :request do
  let(:version) { '/api/v1' }
  let(:email) { Faker::Internet.email }
  let(:name) { Faker::HarryPotter.character }
  let!(:user) { create(:user, email: email, name: name) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(forgot) POST /api/v1/password/forgot' do
    let(:valid_params) {
      {
        email: email,
        name: name
      }
    }

    before { post "#{version}/password/forgot", params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(reset) POST /api/v1/password/reset' do
    let(:valid_params){
      {
        new_password: '12345678',
        new_password_confirmation: '12345678'
      }
    }

    before { post "#{version}/password/reset", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(verify_reset_code) POST /api/v1/password/verify-reset-code' do
    let(:valid_params) {
      {
        email: email,
        name: name
      }
    }

    it 'returns status code :ok' do
      post "#{version}/password/forgot", params: valid_params
      reloaded_user = user.reload
      verify_params = {
        reset_key: reloaded_user.reset_password_token,
        reset_code: reloaded_user.reset_password_code
      }
      post "#{version}/password/verify-reset-code", params: verify_params
      expect(response).to have_http_status(:ok)
    end
  end
end
