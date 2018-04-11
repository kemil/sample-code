require 'rails_helper'

RSpec.describe Api::V1::QuestionImagesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:quiz) { create(:step, guide_id: guide.id, step_type: :quiz) }
  let!(:question) { create(:question, step_id: quiz.id, choices: build_list(:choice, 4)) }
  let!(:question_image) { create(:question_image, question_id: question.id) }

  describe '(create) POST /api/v1/question-images' do
    before do
      picture = fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      post "#{version}/question-images", headers: token_auth, params: { picture: picture }
    end

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/questions/:questionId/image' do
    before { delete "#{version}/questions/#{question.id}/image", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
