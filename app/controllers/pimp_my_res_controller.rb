class PimpMyResController < ApplicationController

  def new
  
  end

 def create
  jobs_url = params[:job_posting_url] || "https://default.jobs.url"

  professional_data = {
    skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
    experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
    projects: ProfessionalApiService.new.get_url("/api/v0/projects"),
    personal_details: ProfessionalApiService.new.get_url("/api/v0/personal_details")
  }

  scraped_jobs = StreetCredScraperService.new(jobs_url).cut_product

  messages = build_messages(professional_data, scraped_jobs)

  openai = OpenAiService.new
  result = openai.chat_completion(messages: messages)

  if result[:choices].present?
    @resume_draft = result[:choices][0][:message][:content]
    render json: { resume_draft: @resume_draft }
  else
    error_message = result[:error] ? result[:error][:message] : "Unknown error from OpenAI"
    render json: { error: error_message }, status: :bad_request
  end
end


  private

  def build_messages(professional_data, scraped_jobs)
    [
      { role: "system", content: "You are a professional resume-writing assistant." },
      { role: "user", content: "Here is my professional data including skills, experiences, projects, and personal details:\n#{professional_data.to_json}" },
      { role: "user", content: "Here are some job listings I want to tailor my resume for:\n#{scraped_jobs.to_json}" },
      { role: "user", content: "Please generate a resume draft in markdown format that highlights my skills and experiences aligned with the job listings." }
    ]
  end
  # def index
  #   # Get the jobs URL from params, or use a default/fallback
  #   jobs_url = params[:jobs_url] || "https://default.jobs.url"

  #   professional_data = {
  #     skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
  #     experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
  #     projects: ProfessionalApiService.new.get_url("/api/v0/projects"),
  #     personal_details: ProfessionalApiService.new.get_url("/api/v0/personal_details")
  #   }

  #   scraped_jobs = StreetCredScraperService.new(jobs_url).cut_product

  #   messages = build_messages(professional_data, scraped_jobs)

  #   openai = OpenAiService.new
  #   result = openai.chat_completion(messages: messages)

  #   render json: {
  #     resume_draft: result[:choices][0][:message][:content]
  #   }
  # end

  # private

  # def build_messages(professional_data, scraped_jobs)
  #   [
  #     { role: "system", content: "You are a professional resume-writing assistant." },
  #     { role: "user", content: "Here is my professional data including skills, experiences, projects, and personal details:\n#{professional_data.to_json}" },
  #     { role: "user", content: "Here are some job listings I want to tailor my resume for:\n#{scraped_jobs.to_json}" },
  #     { role: "user", content: "Please generate a resume draft in markdown format that highlights my skills and experiences aligned with the job listings." }
  #   ]
  # end
end
