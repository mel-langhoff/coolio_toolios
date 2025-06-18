require 'rails_helper'

RSpec.describe OpenAiService, type: :service do
  let(:service) { OpenAiService.new }

  describe '#conn' do
    it 'returns a Faraday connection object' do
      connection = service.conn
      expect(connection).to be_a(Faraday::Connection)
      expect(connection.headers['Authorization']).to include('Bearer')
      expect(connection.headers['Content-Type']).to eq('application/json')
    end
  end

  describe '#get_url', :vcr do
    it 'makes a GET request and returns parsed JSON' do
      # Use a real or mock endpoint that returns JSON
      service = OpenAiService.new
      url = 'https://api.openai.com/v1/models'
      response = service.get_url(url)
      
      expect(response).to be_a(Hash).or be_a(Array)
      # You can add more specific expectations based on the API response shape
    end
  end
end
