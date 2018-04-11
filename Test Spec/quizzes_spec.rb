require 'rails_helper'

RSpec.describe Api::V1::QuizzesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:quiz) { create(:step, guide_id: guide.id, step_type: :quiz) }

  describe '(create) POST /api/v1/quizzes' do
    let(:valid_params) {
      attributes_for(:step,
        guide_id: guide.id,
        step_type: :quiz,
        questions_attributes: attributes_for_list(:question, 5,
          choices_attributes: attributes_for_list(:choice, 4))
        )
    }

    before { post "#{version}/quizzes", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/quizzes/:id' do
    before { get "#{version}/quizzes/#{quiz.id}", headers: token_auth, params: {guide_id: guide.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/quizzes/:id' do
    let(:valid_params) {
      attributes_for(:step,
        guide_id: guide.id,
        step_type: :quiz,
        title: 'Updated',
        questions_attributes: attributes_for_list(:question, 5,
          choices_attributes: attributes_for_list(:choice, 4))
        )
    }

    before { patch "#{version}/quizzes/#{quiz.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/quizzes/:id' do
    before { delete "#{version}/quizzes/#{quiz.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
