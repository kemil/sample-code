require 'rails_helper'

RSpec.describe Api::V1::StepImagesController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:step) { create(:step) }
  let!(:step_image) { create(:step_image, step_id: step.id) }

  describe '(create) POST /api/v1/step-images' do
    before do
      picture = fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      post "#{version}/step-images", headers: token_auth, params: { picture: picture }
    end

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/steps/:stepId' do
    before { delete "#{version}/steps/#{step.id}/image", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
