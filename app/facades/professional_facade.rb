# app/facades/professional_facade.rb
class ProfessionalFacade
  def get_professional_data
    {
      skills: clean_skills,
      experiences: clean_experiences,
      projects: clean_projects
    }
  end

  private

  def api
    @api ||= ProfessionalApiService.new
  end

  def clean_skills
    api.get_url("/api/v0/skills").map { |s| s[:name] }.compact
  end

  def clean_experiences
    api.get_url("/api/v0/experiences").map do |e|
      {
        title:       e[:title],
        company:     e[:company],
        description: e[:description],
        location:    e[:location],
        start_date:  e[:start_date],
        end_date:    e[:end_date]
      }.compact
    end
  end

  def clean_projects
    api.get_url("/api/v0/projects").map do |p|
      {
        name:         p[:name],
        description:  p[:description],
        technologies: p[:technologies],
        github_url:   p[:github_url],
        demo_url:     p[:demo_url]
      }.compact
    end
  end
end
