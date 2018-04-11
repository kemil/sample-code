require 'rails_helper'

RSpec.describe Api::V1::RegistrationController, type: :request do
  let(:version) { '/api/v1' }

  describe '(create) POST /api/v1/registration' do
    let(:valid_attributes) {
      {
        email: Faker::Internet.email,
        name: Faker::HarryPotter.character,
        password: Faker::Number.number(10),
        timezone: 'Kuala Lumpur'
      }
    }

    context 'when the request is valid' do
      before { post "#{version}/registration", params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post "#{version}/registration", params: { email: Faker::Internet.email } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end
  end
end
