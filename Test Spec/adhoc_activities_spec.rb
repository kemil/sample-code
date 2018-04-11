require 'rails_helper'

RSpec.describe Api::V1::AdhocActivitiesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:activity) { create(:schedule_activity, activity_purpose_id: activity_purposes(:work).id, user_id: user.id) }

  describe '(index) GET /api/v1/adhoc-activities' do
    before { get "#{version}/adhoc-activities", params: {since: '1 Jan 2017'}, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(show) GET /api/v1/adhoc-activities/:id' do
    before { get "#{version}/adhoc-activities/#{activity.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/adhoc-activities' do
    let(:valid_params) {
      {
        name: Faker::Hipster.sentence,
        purpose: 'Work',
        day: '1 Oct 2017',
        start_at: '09:30',
        end_at: '11:45',
        priority: 0
      }
    }
    before { post "#{version}/adhoc-activities", params: valid_params, headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(update) PATCH /api/v1/adhoc-activities/:id' do
    let(:valid_params) {
      {
        name: Faker::Hipster.sentence,
        purpose: 'Work',
        day: '1 Oct 2017',
        start_at: '09:30',
        end_at: '11:45',
        priority: 0
      }
    }

    before { patch "#{version}/adhoc-activities/#{activity.id}", params: valid_params, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/adhoc-activities/:id' do
    before { delete "#{version}/adhoc-activities/#{activity.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
