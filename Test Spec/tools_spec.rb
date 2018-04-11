require 'rails_helper'

RSpec.describe Api::V1::ToolsController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:step) { create(:step, guide_id: guide.id) }
  let!(:tools) { create_list(:tool, 10, step_id: step.id) }

  describe '(index) GET /api/v1/tools' do
    before { get "#{version}/tools", headers: token_auth, params: {step_id: step.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/tools' do
    let(:valid_params) {
      {
        step_id: step.id,
        name: Faker::ChuckNorris.fact,
        order: 10
      }
    }

    before { post "#{version}/tools", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/tools/:id' do
    before { get "#{version}/tools/#{tools.last.id}", headers: token_auth, params: {step_id: step.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/tools/:id' do
    let(:valid_params) {
      {
        step_id: step.id,
        name: 'Updated'
      }
    }

    before { patch "#{version}/tools/#{tools.last.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/tools/:id' do
    before { delete "#{version}/tools/#{tools.last.id}", headers: token_auth, params: {step_id: step.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
