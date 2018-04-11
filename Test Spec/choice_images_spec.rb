require 'rails_helper'

RSpec.describe Api::V1::ChoiceImagesController, type: :request do
  let(:version) { '/api/v1' }
  let!(:user) { create(:user) }
  let(:token_auth) { {'Authorization' => "Token #{user.authentication_token}"} }
  let!(:choice) { create(:choice) }
  let!(:choice_image) { create(:choice_image, choice_id: choice.id) }

  describe '(create) POST /api/v1/choice-images' do
    before do
      picture = fixture_file_upload('files/avatar.jpg', 'image/jpeg')
      post "#{version}/choice-images", headers: token_auth, params: { picture: picture }
    end

    it 'returns status code :created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe '(destroy) DELETE /api/v1/choices/:choiceId/image' do
    before { delete "#{version}/choices/#{choice.id}/image", headers: token_auth }

    it 'returns status code :ok' do
      expect(response).to have_http_status(:ok)
    end
  end

end
