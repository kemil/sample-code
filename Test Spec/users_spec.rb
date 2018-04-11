require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :request do
  let(:version) { '/api/v1' }
  let!(:users) { create_list(:user, 10) }
  let(:user) { users.first }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(index) GET /api/v1/users' do
    before { get "#{version}/users", headers: token_auth }

    it 'return status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe '(suggest) GET /api/v1/users/suggest' do
    before { get "#{version}/users/suggest", headers: token_auth, params: {query: 'john'} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(show) GET /api/v1/users/:id' do
    context 'when the request is valid' do
      before { get "#{version}/users/#{user.id}", headers: token_auth }

      it 'return status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe '(account) GET /api/v1/users/account' do
    context 'when the request is valid' do
      before { get "#{version}/users/account", headers: token_auth }

      it 'return status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe '(update) PATCH /api/v1/users/:id' do
    before { patch "#{version}/users/#{user.id}", headers: token_auth, params: {name: Faker::HarryPotter.character} }

    it 'return status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe '(destroy) DELETE /api/v1/users/:id' do
    before { delete "#{version}/users/#{user.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
