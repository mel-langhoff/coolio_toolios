class ProfessionalApiService

  def conn
    Faraday.new(url: "http://localhost:3001") do |faraday|
      faraday.headers["Content-Type"] = "application/json"
      faraday.adapter Faraday.default_adapter
    end
  end

  def get_url(url)
    response = conn.get(url)
    JSON.parse(response.body, symbolize_names: true)
  end

  def skills
    get_url("/api/v0/skills")
  end

  def experiences
    get("/api/v0/experiences")
  end

  def projects
    get("/api/v0/projects")
  end

  def personal_details
    get("/api/v0/personal_details")
  end
end
