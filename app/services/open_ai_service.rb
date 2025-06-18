class OpenAiService
  def initialize
  end

  def conn
    Faraday.new(url: 'https://api.openai.com') do |faraday|
      faraday.request :url_encoded
      faraday.headers['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"
      faraday.headers['Content-Type'] = 'application/json'
    end
  end

  def get_url(url)
    response = conn.get(url)
    JSON.parse(response.body, symbolize_names: true)
  end
end
