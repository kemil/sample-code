require 'rails_helper'

RSpec.describe Api::V1::ReleasesController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let!(:programs) { create_list(:program, 10, user_id: user.id, private: true) }
  let(:program_id) { programs.first.id }
  let!(:release) { create(:program, user_id: user.id, private: true, program_id: programs.last.id) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(index) GET /api/v1/releases' do
    before { get "#{version}/releases", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(owned) GET /api/v1/releases/owned' do
    before { get "#{version}/releases/owned", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(subscribed) GET /api/v1/releases/subscribed' do
    before { get "#{version}/releases/subscribed", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(show) GET /api/v1/releases/:urlIdentifier' do
    before { get "#{version}/releases/#{release.url_identifier}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/releases' do
    before { post "#{version}/releases", headers: token_auth, params: {program_id: program_id} }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/releases' do
    before { delete "#{version}/releases", headers: token_auth, params: {program_id: program_id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
