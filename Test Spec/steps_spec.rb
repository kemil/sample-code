require 'rails_helper'

RSpec.describe Api::V1::StepsController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:step) { create(:step, guide_id: guide.id) }

  describe '(created) POST /api/v1/steps' do
    let(:valid_params) {
      {
        guide_id: guide.id,
        title: Faker::ChuckNorris.fact,
        duration: 10,
        order: 1,
        description: Faker::Lorem.paragraph,
        toolsAttributes: [
          {
            name: Faker::ChuckNorris.fact,
            order: 1,
            toolSuggestionsAttributes: [
              {
                title: Faker::Hipster.word,
                url: Faker::Internet.url,
                image_url: Faker::LoremPixel.image,
                price: 10
              }
            ]
          }
        ]
      }
    }

    before { post "#{version}/steps", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/steps/:id' do
    before { get "#{version}/steps/#{step.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/steps/:id' do
    let(:valid_params) {
      {
        title: 'Updated',
        duration: 15
      }
    }

    before { patch "#{version}/steps/#{step.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/steps/:id' do
    before { delete "#{version}/steps/#{step.id}", headers: token_auth, params: {guide_id: guide.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
