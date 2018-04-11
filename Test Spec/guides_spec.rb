require 'rails_helper'

RSpec.describe Api::V1::GuidesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:activity_with_guide) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity_with_guide, guideable_type: 'ProgramActivity') }

  describe '(create) POST /api/v1/guides' do
    let(:valid_params) {
      {
        guideable_id: activity.id,
        guideable_type: 'ProgramActivity',
        private: false,
        collaborative: true,
        premium: false,
        autofit: true,
        guide_type: 1
      }
    }

    before { post "#{version}/guides", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/guides/:id' do
    let(:valid_params) {
      {
        guideable_id: activity_with_guide.id,
        guideable_type: 'ProgramActivity'
      }
    }

    before { get "#{version}/guides/#{guide.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/guides/:id' do
    let(:valid_params) {
      {
        guideable_id: activity_with_guide.id,
        guideable_type: 'ProgramActivity',
        private: true,
        collaborative: true,
        premium: true,
        autofit: true,
        guide_type: 2
      }
    }

    before { patch "#{version}/guides/#{guide.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/guides/:id' do
    let(:valid_params) {
      {
        guideable_id: activity_with_guide.id,
        guideable_type: 'ProgramActivity'
      }
    }

    before { delete "#{version}/guides/#{guide.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
