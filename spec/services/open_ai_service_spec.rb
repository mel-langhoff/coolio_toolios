require 'rails_helper'

RSpec.describe OpenAiService, type: :service do
  let(:service) { OpenAiService.new }

  describe '#chat_completion', :vcr do
    it 'sends chat messages and returns parsed response' do
      messages = [
        { role: "system", content: "You are a professional resume-writing assistant." },
        { role: "user", content: "Hello, who won the world series in 2020?" }
      ]

      response = service.chat_completion(messages: messages)

      expect(response).to be_a(Hash)
      expect(response).to have_key(:choices)
      expect(response[:choices]).to be_an(Array)
      expect(response[:choices].first).to have_key(:message)
      expect(response[:choices].first[:message]).to have_key(:content)
      expect(response[:choices].first[:message][:content]).to be_a(String)
    end
  end
end
