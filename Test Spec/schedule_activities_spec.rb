require 'rails_helper'

RSpec.describe Api::V1::ScheduleActivitiesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:release) { create(:program, user_id: user.id, program_id: program.id) }
  let!(:schedule) { create(:schedule, user_id: user.id, ref_id: release.id) }
  let!(:activity) { create(:schedule_activity, user_id: user.id, schedule_id: schedule.id, activity_purpose_id: activity_purposes(:work).id) }

  describe '(show) GET /api/v1/schedules/:schedule_id/activities/:id' do
    before { get "#{version}/schedules/#{schedule.id}/activities/#{activity.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(update) PATCH /api/v1/schedules/:schedule_id/activities/:id' do
    let(:valid_params) {
      {
        name: Faker::Hipster.sentence,
        purpose: 'Rest',
        priority: 1,
        start: '2017-09-30 05:00',
        end: '2017-09-30 10:00'
      }
    }

    before { patch "#{version}/schedules/#{schedule.id}/activities/#{activity.id}", params: valid_params, headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
