require 'rails_helper'

RSpec.describe Api::V1::ProgramImagesController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:program_image) { create(:program_image, program_id: program.id) }

  describe '(create) POST /api/v1/programs/:programId/image' do
    before do
      picture = fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      valid_params = { picture: picture }
      post "#{version}/programs/#{program.id}/image", headers: token_auth, params: valid_params
    end

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/programs/:programId/image' do
    before { delete "#{version}/programs/#{program.id}/image", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
