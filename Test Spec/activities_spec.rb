require 'rails_helper'

RSpec.describe Api::V1::ActivitiesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id, day: 2) }
  let!(:activities) { create_list(:program_activity, 10, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }

  describe '(index) GET /api/v1/activities' do
    before { get "#{version}/activities", params: {program_id: program.id, day: 1}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/activities' do
    let(:valid_params) {
      {
        program_id: program.id,
        name: Faker::Hipster.sentence,
        purpose: 'Work',
        day: 1,
        start_at: '2017-01-01',
        end_at: '2017-01-02',
        address: Faker::Lorem.sentence,
        priority: 0
      }
    }
    before { post "#{version}/activities", params: valid_params, headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(show) GET /api/v1/activities/:id' do
    before { get "#{version}/activities/#{activity.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/activities/:id' do
    before { patch "#{version}/activities/#{activity.id}", params: {name: Faker::Hipster.sentence}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(pin) PATCH /api/v1/activities/:id/pin' do
    before { patch "#{version}/activities/#{activity.id}/pin", params: {pinned: true}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(key_activity) PATCH /api/v1/activities/:id/key-activity' do
    before { patch "#{version}/activities/#{activity.id}/key-activity", params: {key_activity: true}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(stash) PATCH /api/v1/activities/:id/stash' do
    before { patch "#{version}/activities/#{activity.id}/stash", params: {stash: true}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/activities/:id' do
    before { delete "#{version}/activities/#{activity.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
