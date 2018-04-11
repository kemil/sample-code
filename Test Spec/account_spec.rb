require 'rails_helper'

RSpec.describe Api::V1::AccountController, type: :request do
  let(:version) { '/api/v1' }
  let(:password) { Faker::Number.number(10) }
  let!(:user) { create(:user, password: password) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(picture) PATCH /api/v1/account/picture' do
    before do
      avatar = fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      patch "#{version}/account/picture", headers: token_auth, params: { avatar: avatar }
    end

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(detail) PATCH /api/v1/account/detail' do
    let(:valid_params) {
      {
        email: 'adit.mahdar@gmail.com',
        password: '12345678',
        current_password: password
      }
    }

    before { patch "#{version}/account/detail", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create_password) POST /api/v1/account/create-password' do
    let(:valid_params) {
      {
        password: '12345678',
        password_confirmation: '12345678'
      }
    }

    before { post "#{version}/account/create-password", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(rollback_email) POST /api/v1/account/rollback-email' do
    let(:valid_params) {
      {
        email: 'adit.mahdar@gmail.com',
        current_password: password
      }
    }

    it 'returns status code :ok' do
      patch "#{version}/account/detail", headers: token_auth, params: valid_params
      rollback_params = {
        token: user.reload.change_email_token,
        password: password,
        confirm_password: password
      }
      post "#{version}/account/rollback-email", headers: token_auth, params: rollback_params
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/account/compromised' do
    context 'when the request is valid' do
      it 'returns status code 200' do
        user.update(compromise_email_token: Faker::Number.number(10))
        post("#{version}/account/compromised", params: {token: user.compromise_email_token})
        expect(response).to have_http_status(200)
      end
    end

    context 'when the request is invalid' do
      before { post "#{version}/account/compromised", params: {token: '123'} }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end
end
