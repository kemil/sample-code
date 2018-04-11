require 'rails_helper'

RSpec.describe Api::V1::SubscribesController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user2.id) }
  let!(:release) { create(:program, user_id: user2.id, program_id: program.id) }

  describe '(create) POST /api/v1/releases/:id/subscribe' do
    before do
      picture = fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      post "#{version}/releases/#{release.id}/subscribe", headers: token_auth
    end

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/releases/:id/unsubscribe' do
    before { delete "#{version}/releases/#{release.id}/unsubscribe", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
