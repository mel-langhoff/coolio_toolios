class PimpMyResController < ApplicationController
  def new
  def show
    @hustle = Hustle.find(params[:id])
    @resume_markdown = @hustle.resume["generated_resume"]
  end

  end

  def create
    jobs_url = params[:job_posting_url] || "https://default.jobs.url"

    professional_data = {
      skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
      experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
      projects: ProfessionalApiService.new.get_url("/api/v0/projects"),
    }

    @scraped_jobs = StreetCredScraperService.new(jobs_url).cut_product
    Rails.logger.info "Scraped jobs: #{@scraped_jobs}"

    messages = build_messages(professional_data, @scraped_jobs)
    openai = OpenAiService.new
    result = openai.chat_completion(messages: messages)

    if result[:choices].present?
      @resume_draft = result[:choices][0][:message][:content]
      @resume_markdown = @resume_draft

      job_title = @scraped_jobs.first["title"]
      company = CompanyNameExtractorService.new(URI.open(jobs_url).read).extract
      description = @scraped_jobs.first["description"]

      @hustle = Hustle.create!(
        job_url: jobs_url,
        job_title: job_title,
        company: company,
        job_description: description,
        resume: {
          skills: professional_data[:skills],
          experiences: professional_data[:experiences],
          projects: professional_data[:projects],
          generated_resume: @resume_draft
        }
      )

      redirect_to pimp_my_res_show_path(@hustle.id)
    else
      error_message = result[:error] ? result[:error][:message] : "Unknown error from OpenAI"
      render json: { error: error_message }, status: :bad_request
    end  
  end

  def show
    # Here you should load the hustle or resume to display
    @hustle = Hustle.find(params[:id])
    @resume_markdown = @hustle.resume["generated_resume"]
  end

  private

  def build_messages(professional_data, scraped_jobs)
    [
      { role: "system", content: "You are a professional resume-writing assistant." },
      { role: "user", content: "Here is my professional data including skills, experiences, projects, and personal details:\n#{professional_data.to_json}" },
      { role: "user", content: "Here are some job listings I want to tailor my resume for:\n#{scraped_jobs.to_json}" },
      { role: "user", content: "Please generate a resume for professional experience and skills resume draft and also plug in key words from the posting in the resume and in markdown format that highlights my skills and experiences aligned with the job listings." }
    ]
  end
end
