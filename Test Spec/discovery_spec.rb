require 'rails_helper'

RSpec.describe Api::V1::DiscoveryController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(content) GET /api/v1/discovery/content' do
    before { get "#{version}/discovery/content", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(content_all) GET /api/v1/discovery/content-all' do
    before { get "#{version}/discovery/content-all", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(search) GET /api/v1/discovery/search' do
    before { get "#{version}/discovery/search", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(fresh) GET /api/v1/discovery/fresh' do
    before { get "#{version}/discovery/fresh", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(others) GET /api/v1/discovery/others' do
    before { get "#{version}/discovery/others", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
