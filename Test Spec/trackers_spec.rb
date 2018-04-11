require 'rails_helper'

RSpec.describe Api::V1::TrackersController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:event) { create(:event, user_id: user.id, activity_purpose_id: activity_purposes(:work).id) }

  describe '(index) GET /api/v1/trackers' do
    before { get "#{version}/trackers", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/trackers' do
    before { post "#{version}/trackers", headers: token_auth, params: {event_id: event.id} }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/trackers' do
    let!(:session) { create(:session, user_id: user.id, event_id: event.id) }
    before { delete "#{version}/trackers", headers: token_auth, params: {event_id: event.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  # describe '(report) GET /api/v1/trackers/report' do
  #   let(:valid_params) {
  #     {
  #       from: '17/09/2017',
  #       to: '20/09/2017',
  #       timeframe: 'daily'
  #     }
  #   }

  #   before { get "#{version}/trackers/report", headers: token_auth, params: valid_params }

  #   it 'returns status code :ok' do
  #     expect(response).to have_http_status(:ok)
  #   end
  # end

  # describe '(upcoming) GET /api/v1/trackers/upcoming' do
  #   before { get "#{version}/trackers/upcoming", headers: token_auth }

  #   it 'returns status code :ok' do
  #     expect(response).to have_http_status(:ok)
  #   end
  # end

  # describe '(skip) POST /api/v1/trackers/skip' do
  #   before { post "#{version}/trackers/skip", headers: token_auth, params: {event_id: event.id, remarks: 'Test'} }

  #   it 'returns status code :ok' do
  #     expect(response).to have_http_status(:ok)
  #   end
  # end
end
