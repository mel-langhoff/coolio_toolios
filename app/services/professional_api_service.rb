class ProfessionalApiClient
  BASE_URL = "http://localhost:3000"

  def self.get(path)
    response = Faraday.get("#{BASE_URL}#{path}")
    raise "API Error: #{response.status}" unless response.success?
    JSON.parse(response.body)
  end

  def self.skills
    get("/api/v0/skills")
  end

  def self.experiences
    get("/api/v0/experiences")
  end

  def self.projects
    get("/api/v0/projects")
  end

  def self.personal_details
    get("/api/v0/personal_details")
  end
end
