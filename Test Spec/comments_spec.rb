require 'rails_helper'

RSpec.describe Api::V1::CommentsController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:step) { create(:step, guide_id: guide.id) }
  let!(:comment) { create(:comment, user_id: user.id, step_id: step.id) }

  describe '(index) GET /api/v1/steps/:step_id/comments' do
    before { get "#{version}/steps/#{step.id}/comments", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/steps/:step_id/comments' do
    let(:valid_params) {
      {
        body: Faker::ChuckNorris.fact
      }
    }

    before { post "#{version}/steps/#{step.id}/comments", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/steps/:step_id/comments/:id' do
    before { get "#{version}/steps/#{step.id}/comments/#{comment.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/steps/:step_id/comments/:id' do
    let(:valid_params) {
      {
        body: Faker::ChuckNorris.fact
      }
    }

    before { patch "#{version}/steps/#{step.id}/comments/#{comment.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/steps/:step_id/comments/:id' do
    before { delete "#{version}/steps/#{step.id}/comments/#{comment.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
