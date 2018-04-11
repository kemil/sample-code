require 'rails_helper'

RSpec.describe Api::V1::RepliesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:step) { create(:step, guide_id: guide.id) }
  let!(:comment) { create(:comment, user_id: user.id, step_id: step.id) }
  let!(:reply) { create(:comment, user_id: user.id, step_id: step.id, comment_id: comment.id) }

  describe '(index) GET /api/v1/comments/:comment_id/replies' do
    before { get "#{version}/comments/#{comment.id}/replies", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/comments/:comment_id/replies' do
    let(:valid_params) {
      {
        body: Faker::ChuckNorris.fact
      }
    }

    before { post "#{version}/comments/#{comment.id}/replies", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(update) PATCH /api/v1/comments/:comment_id/replies/:id' do
    let(:valid_params) {
      {
        body: Faker::ChuckNorris.fact
      }
    }

    before { patch "#{version}/comments/#{comment.id}/replies/#{reply.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/comments/:comment_id/replies/:id' do
    before { delete "#{version}/comments/#{comment.id}/replies/#{reply.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end