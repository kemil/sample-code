require 'rails_helper'

RSpec.describe Api::V1::ClassGroupsController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let!(:class_groups) { create_list(:class_group, 5, user_id: user.id) }
  let(:class_group_id) { class_groups.first.id }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe "(index) GET /api/v1/class-groups" do
    before { get "#{version}/class-groups", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(owned) GET /api/v1/class-groups/owned" do
    before { get "#{version}/class-groups/owned", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(create) POST /api/v1/class-groups" do
    let(:valid_params) {
      {
        name: Faker::ChuckNorris.fact,
        description: Faker::Lorem.paragraph,
        start_date: '1 Jan 2018',
        end_date: '25 Jan 2018',
        size: 20,
        private: false,
        image: fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      }
    }

    before { post "#{version}/class-groups", params: valid_params, headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe "(show) GET /api/v1/class-groups/:id" do
    before { get "#{version}/class-groups/#{class_group_id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(update) PATCH /api/v1/class-groups/:id" do
    before { patch "#{version}/class-groups/#{class_group_id}", params: {name: Faker::ChuckNorris.fact}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "(destroy) DELETE /api/v1/class-groups/:id" do
    before { delete "#{version}/class-groups/#{class_group_id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
