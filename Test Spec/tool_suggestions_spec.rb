require 'rails_helper'

RSpec.describe Api::V1::ToolSuggestionsController, type: :request do
  fixtures :activity_purposes
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:program) { create(:program, user_id: user.id) }
  let!(:activity) { create(:program_activity, program_id: program.id, activity_purpose_id: activity_purposes(:work).id) }
  let!(:guide) { create(:guide, guideable: activity, guideable_type: 'ProgramActivity') }
  let!(:step) { create(:step, guide_id: guide.id) }
  let!(:tool) { create(:tool, step_id: step.id) }
  let!(:tool_suggestions) { create_list(:tool_suggestion, 10, tool_id: tool.id) }
  let(:tool_suggestion) { tool_suggestions.first }

  describe '(index) GET /api/v1/tool-suggestions' do
    before { get "#{version}/tool-suggestions", headers: token_auth, params: {tool_id: tool.id} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(search) GET /api/v1/tool-suggestions' do
    before { get "#{version}/tool-suggestions/search", headers: token_auth, params: {keyword: 'macbook'} }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(create) POST /api/v1/tool-suggestions' do
    let(:valid_params) {
      {
        tool_id: tool.id,
        title: Faker::Hipster.word,
        url: Faker::Internet.url,
        image_url: Faker::LoremPixel.image,
        price: 10
      }
    }

    before { post "#{version}/tool-suggestions", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(update) PATCH /api/v1/tool-suggestions/:id' do
    let(:valid_params) {
      {
        title: Faker::Hipster.word,
        price: 25
      }
    }

    before { patch "#{version}/tool-suggestions/#{tool_suggestion.id}", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(destroy) DELETE /api/v1/tool-suggestions/:id' do
    before { delete "#{version}/tool-suggestions/#{tool_suggestion.id}", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '(bulk_create) POST /api/v1/tool-suggestions' do
    let(:valid_params) {
      {
        tool_id: tool.id,
        tool_suggestions: [
          {
            title: Faker::Hipster.word,
            url: Faker::Internet.url,
            image_url: Faker::LoremPixel.image,
            price: 10
          },
          {
            title: Faker::Hipster.word,
            url: Faker::Internet.url,
            image_url: Faker::LoremPixel.image,
            price: 10
          },
          {
            title: Faker::Hipster.word,
            url: Faker::Internet.url,
            image_url: Faker::LoremPixel.image,
            price: 10
          }
        ]
      }
    }

    before { post "#{version}/tool-suggestions/bulk-create", headers: token_auth, params: valid_params }

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(bulk_update) PUT /api/v1/tool-suggestions' do
    let(:valid_params) {
      {
        tool_id: tool.id,
        tool_suggestions: [
          {
            title: Faker::Hipster.word,
            url: Faker::Internet.url,
            image_url: Faker::LoremPixel.image,
            price: 10
          },
          {
            title: Faker::Hipster.word,
            url: Faker::Internet.url,
            image_url: Faker::LoremPixel.image,
            price: 10
          }
        ]
      }
    }

    before { put "#{version}/tool-suggestions/bulk-update", headers: token_auth, params: valid_params }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
