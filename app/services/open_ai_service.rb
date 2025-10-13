# app/services/open_ai_service.rb
require "faraday"
require "json"

class OpenAiService
  def initialize
    @api_key = Rails.application.credentials.dig(:openai, :openai_api_key)
  end

  def conn
    Faraday.new(url: "https://api.openai.com") do |faraday|
      faraday.request :url_encoded
      faraday.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}"
      faraday.headers["Content-Type"] = "application/json"
    end
  end

  def get_url(url)
    response = conn.get(url)
    JSON.parse(response.body, symbolize_names: true)
  end

  def chat_completion(messages:, model: "gpt-4o-mini")
    body = {
      model: model,
      messages: messages
    }.to_json

    response = conn.post("/v1/chat/completions", body)
    JSON.parse(response.body, symbolize_names: true)
  end
end
