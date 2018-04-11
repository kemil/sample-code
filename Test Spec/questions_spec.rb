require 'rails_helper'

RSpec.describe Api::V1::QuestionsController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:quiz) { create(:step, guide_id: guide.id, step_type: :quiz) }
  let!(:question) { create(:question, step_id: quiz.id, choices: build_list(:choice, 4)) }

  describe '(destroy) DELETE /api/v1/questions/:id' do
    before { delete "#{version}/questions/#{question.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
