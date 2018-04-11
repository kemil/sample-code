require 'rails_helper'

# TODO Add request test
RSpec.describe Api::V1::BulkActivitiesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }

  describe '(create) POST /api/v1/bulk-activities' do
    let(:valid_params) {
      {
        activities: [
          {
            program: program.id,
            name: Faker::Hipster.sentence,
            purpose: 'Work',
            day: 1,
            start: '09:00',
            end: '10:30',
            address: Faker::Lorem.sentence,
            priority: 0
          }
        ]
      }
    }
    before { post "#{version}/bulk-activities", params: valid_params, headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(update) PATCH /api/v1/bulk-activities' do
    let(:valid_params) {
      {
        activities: [
          {
            id: activity.id,
            program: program.id,
            name: Faker::Hipster.sentence,
            purpose: 'Work',
            day: 1,
            start: '09:00',
            end: '10:30',
            address: Faker::Lorem.sentence,
            priority: 0
          }
        ]
      }
    }
    before { patch "#{version}/bulk-activities", params: valid_params, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(paste) POST /api/v1/bulk-activities/paste' do
    let(:valid_params) {
      {
        activities: [
          {
            id: activity.id,
            day: 2,
            start: '09:00',
            end: '10:30'
          }
        ]
      }
    }
    before { post "#{version}/bulk-activities/paste", params: valid_params, headers: token_auth }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/bulk-activities' do
    let(:valid_params) {
      {
        ids: [activity.id]
      }
    }
    before { delete "#{version}/bulk-activities", params: valid_params, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
