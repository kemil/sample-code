require 'rails_helper'

RSpec.describe Api::V1::TagsController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }

  describe '(index) GET /api/v1/tags' do
    before { get "#{version}/tags", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
