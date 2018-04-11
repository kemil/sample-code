require 'rails_helper'

RSpec.describe Api::V1::SchedulesController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:schedule) { create(:schedule, user_id: user.id, ref_id: release.id) }
  let!(:schedule_activities) { create_list(:schedule_activity, 10, user_id: user.id, schedule_id: schedule.id, activity_purpose_id: activity_purposes(:work).id) }

  let!(:release) { create(:program, user_id: user.id, program_id: program.id) }
  let!(:release_image) { create(:program_image, program_id: release.id) }
  let!(:activities) { create_list(:program_activity, 5, program_id: release.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:tags) { create_list(:tag, 3) }
  let!(:programs_tag) { create(:programs_tag, tag_id: tags.first.id, program_id: release.id) }

  let!(:guide) { create(:guide, guideable: activities.first, guideable_type: 'ProgramActivity') }
  let!(:step) { create(:step, guide_id: guide.id) }
  let!(:tools) { create_list(:tool, 5, step_id: step.id) }
  let!(:tool_suggestions) { create_list(:tool_suggestion, 5, tool_id: tools.first.id) }
  let!(:quiz) { create(:step, guide_id: guide.id, step_type: :quiz) }
  let!(:question) { create(:question, step_id: quiz.id, choices: build_list(:choice, 4)) }

  describe '(index) GET /api/v1/schedules' do
    before { get "#{version}/schedules", headers: token_auth, params: {since: '1 Jan 2017'} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(activities) GET /api/v1/schedules/activities' do
    before { get "#{version}/schedules/activities", headers: token_auth, params: {since: '1 Jan 2017'} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(release) GET /api/v1/schedules/release' do
    before { get "#{version}/schedules/release", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/schedules' do
    before { post "#{version}/schedules", headers: token_auth, params: {release_id: release.id, start_date: '1 Oct 2017'} }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(create) POST /api/v1/schedules #activities' do
    let(:valid_params) {
      {
        release_id: release.id,
        activities: activities.map(&:rspec_create_schedule_params)
      }
    }

    before { post "#{version}/schedules", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/schedules/:id' do
    before { delete "#{version}/schedules/#{schedule.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
