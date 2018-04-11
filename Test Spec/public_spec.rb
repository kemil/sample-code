require 'rails_helper'

RSpec.describe Api::V1::PublicController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }

  describe '(contact) POST /api/v1/public/contact' do
    let(:valid_params) {
      {
        recaptcha_response: 'true',
        name: Faker::HarryPotter.character,
        email: Faker::Internet.email,
        message: Faker::Lorem.paragraph
      }
    }

    context 'when the request is valid' do
      before { post "#{version}/public/contact", params: valid_params }

      it 'returns status code :ok' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the request is invalid' do
      before { post "#{version}/public/contact", params: {name: Faker::HarryPotter.character} }

      it 'returns status code :unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '(register_interest) POST /api/v1/public/register-interest' do
    let(:valid_params) {
      {
        name: Faker::HarryPotter.character,
        email: Faker::Internet.email
      }
    }

    before { post "#{version}/public/register-interest", params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  # describe '(programs_show) GET /api/v1/public/programs/:urlIdentifier' do
  #   before { get "#{version}/public/programs/#{program.url_identifier}" }

  #   it 'returns status code :ok' do
  #     expect(response).to have_http_status(:ok)
  #   end
  # end

  describe '(guides_show) GET /api/v1/public/guides/:id' do
    before { get "#{version}/public/guides/#{guide.id}" }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
