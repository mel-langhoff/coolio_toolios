class ResumePlugService
  def initialize(jobs_url:)
    @jobs_url = jobs_url
  end

  def call
    professional_data = fetch_professional_data
    scraped_jobs = scrape_jobs
    return { error: "No jobs found." } if scraped_jobs.empty?

    resume_draft = generate_resume(professional_data, scraped_jobs)
    return { error: "OpenAI did not return content." } unless resume_draft

    hustle = save_hustle(scraped_jobs, resume_draft, professional_data)

    { hustle: hustle }
  rescue => e
    { error: e.message }
  end

  private

  def fetch_professional_data
    {
      skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
      experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
      projects: ProfessionalApiService.new.get_url("/api/v0/projects")
    }
  end

  def scrape_jobs
    StreetCredScraperService.new(@jobs_url).cut_product
  end

  def generate_resume(professional_data, scraped_jobs)
    messages = build_messages(professional_data, scraped_jobs)
    result = OpenAiService.new.chat_completion(messages: messages)
    result[:choices]&.first&.dig(:message, :content)
  end

  def build_messages(professional_data, scraped_jobs)
    [
      { role: "system", content: "You are a professional resume-writing assistant." },
      { role: "user", content: "Here is my professional data:\n#{professional_data.to_json}" },
      { role: "user", content: "Here are some job listings:\n#{scraped_jobs.to_json}" },
      { role: "user", content: "Generate a markdown resume aligned with these jobs." }
    ]
  end

  def save_hustle(scraped_jobs, resume_draft, professional_data)
    job = scraped_jobs.first
    html = URI.open(@jobs_url).read
    company = CompanyNameExtractorService.new(html).extract

    Hustle.create!(
      job_url: @jobs_url,
      job_title: job["title"] || "Unknown Job Title",
      company: company,
      job_description: job["description"] || "No description provided.",
      resume: {
        skills: professional_data[:skills],
        experiences: professional_data[:experiences],
        projects: professional_data[:projects],
        generated_resume: resume_draft
      }
    )
  end
end