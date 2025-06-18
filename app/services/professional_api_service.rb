class ProfessionalApiService
  
  # def initialize(data)
  #   @data = data
  # end

  def conn
    Faraday.new(url: "http://localhost:3000") do |faraday|
      faraday.headers["Content-Type"] = "application/json"
      faraday.adapter Faraday.default_adapter
    end
  end

  def get_url(url)
    response = conn.get(url)
    JSON.parse(response.body, symbolize_names: true)
  end

  # def self.get(path)
  #   response = Faraday.get("#{BASE_URL}#{path}")
  #   raise "API Error: #{response.status}" unless response.success?
  #   JSON.parse(response.body)
  # end

  def self.skills
    get("/api/v0/skills")
  end

  # def self.experiences
  #   get("/api/v0/experiences")
  # end

  # def self.projects
  #   get("/api/v0/projects")
  # end

  # def self.personal_details
  #   get("/api/v0/personal_details")
  # end
end
