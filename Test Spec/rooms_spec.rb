require 'rails_helper'

RSpec.describe Api::V1::RoomsController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:room) { create(:room, participants: [build(:participant, user_id: user.id), build(:participant, user_id: user2.id)]) }
  # let!(:participant) { create(:participant, room_id: room.id, user_id: user.id) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(index) GET /api/v1/rooms' do
    before { get "#{version}/rooms", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/rooms' do
    let(:valid_params) {
      {
        name: 'Test',
        description: 'Test',
        room_type: 'group_chat',
        participants_attributes: [
          {
            user_id: user.id,
            role: 'publisher'
          },
          {
            user_id: user2.id,
            role: 'publisher'
          }
        ]
      }
    }

    before { post "#{version}/rooms", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/rooms/:id' do
    before { get "#{version}/rooms/#{room.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/rooms/:id' do
    let(:valid_params) {
      {
        name: 'Updated',
        description: 'Updated'
      }
    }

    before { patch "#{version}/rooms/#{room.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(token) POST /api/v1/rooms/:id/token' do
    before { post "#{version}/rooms/#{room.id}/token", headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/rooms/:id' do
    before { delete "#{version}/rooms/#{room.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
