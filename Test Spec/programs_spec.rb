require 'rails_helper'

RSpec.describe Api::V1::ProgramsController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let!(:programs) { create_list(:program, 10, user_id: user.id, private: true) }
  let(:program_id) { programs.first.id }
  let!(:release) { create(:program, user_id: user.id, private: true, program_id: program_id) }
  fixtures :activity_purposes
  let!(:activity) { create(:program_activity, program_id: program_id, activity_purpose_id: activity_purposes(:work).id) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe "(latest) GET /api/v1/programs/latest" do
    before { get "#{version}/programs/latest" }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(index) GET /api/v1/programs" do
    before { get "#{version}/programs", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(create) POST /api/v1/programs" do
    let(:valid_params) {
      {
        title: Faker::ChuckNorris.fact,
        summary: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph,
        private: true,
        publish: true
      }
    }

    before { post "#{version}/programs", params: valid_params, headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe "(show) GET /api/v1/programs/:id" do
    before { get "#{version}/programs/#{program_id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(update) PATCH /api/v1/programs/:id" do
    before { patch "#{version}/programs/#{program_id}", params: {title: Faker::ChuckNorris.fact, tags: ['foo', 'test']}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(destroy) DELETE /api/v1/programs/:id" do
    before { delete "#{version}/programs/#{program_id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(release) POST /api/v1/programs/:id/release" do
    before { post "#{version}/programs/#{program_id}/release", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(whitelist) POST /api/v1/programs/:id/whitelist" do
    let(:valid_params) {
      {
        email: %w(test1@mailinator.com test2@mailinator.com test3@mailinator.com)
      }
    }
    before { post "#{version}/programs/#{program_id}/whitelist", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
