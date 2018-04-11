require 'rails_helper'

RSpec.describe Api::V1::SandboxController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(train_bot) POST /api/v1/sandbox/train-bot' do
    let(:valid_params) {
      {
        text: Faker::ChuckNorris.fact,
        purpose: %w(Work Play Grow Rest).sample
      }
    }

    before { post "#{version}/sandbox/train-bot", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(classify_work) POST /api/v1/sandbox/classify-work' do
    let(:valid_params) {
      {
        text: 'Work on Lifestak',
        purpose: 'Work'
      }
    }

    before do
      post "#{version}/sandbox/train-bot", headers: token_auth, params: valid_params
      post "#{version}/sandbox/classify-work", headers: token_auth, params: { text: 'Work on Lifestak' }
    end

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
