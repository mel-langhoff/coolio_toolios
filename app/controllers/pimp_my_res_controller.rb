# app/controllers/pimp_my_res_controller.rb
class PimpMyResController < ApplicationController

  def new
  end

  def show
    @resume_markdown = params[:resume_markdown] || "No resume data available."
  end

  def create
    jobs_url = params[:job_posting_url] || "https://default.jobs.url"

    # 🔹 Fetch professional data from your internal API
    professional_data = {
      skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
      experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
      projects: ProfessionalApiService.new.get_url("/api/v0/projects"),
    }

    # 🔹 Scrape job posting data
    @scraped_jobs = StreetCredScraperService.new(jobs_url).cut_product
    Rails.logger.info "Scraped jobs: #{@scraped_jobs}"

    # Safely extract text body from scraped data
    body_text = @scraped_jobs.first[:description] rescue "No description available."

    # 🔹 Build messages for OpenAI
    messages = build_messages(professional_data, @scraped_jobs, body_text)

    # 🔹 Send prompt to OpenAI
    openai = OpenAiService.new
    result = openai.chat_completion(messages: messages)

    if result[:choices].present?
      @resume_draft = result[:choices][0][:message][:content]
      @resume_markdown = @resume_draft

      # 🔹 Extract job metadata
      job_title   = @scraped_jobs.first[:title] rescue "Unknown Title"
      company     = @scraped_jobs.first[:company] rescue "Unknown Company"
      description = @scraped_jobs.first[:description] rescue "No description provided."

      # 🔹 Create Hustle record
      Rails.logger.info "Creating Hustle record..."
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

      if @hustle.persisted?
        Rails.logger.info "✅ Hustle created with ID: #{@hustle.id}"
      else
        Rails.logger.error "❌ Hustle failed: #{@hustle.errors.full_messages.join(', ')}"
      end

      render :show
    else
      error_message = result[:error] ? result[:error][:message] : "Unknown error from OpenAI"
      render json: { error: error_message }, status: :bad_request
    end  
  rescue => e
    Rails.logger.error "💥 Error in PimpMyResController#create: #{e.message}"
    render plain: "Something went wrong: #{e.message}", status: 500
  end

  private

  # 🔹 Updated to accept body_text as an argument
  def build_messages(professional_data, scraped_jobs, body_text)
    [
      { role: "system", content: "You are a professional resume-writing assistant that optimizes for ATS (Applicant Tracking Systems)." },
      { role: "user", content: "Here is my professional data including skills, experiences, projects, and personal details:\n#{professional_data.to_json}" },
      { role: "user", content: "What is the name of the company hiring for this role?\n\n#{body_text}" },
      { role: "user", content: "Here are some job listings I want to tailor my resume for:\n#{scraped_jobs.to_json}" },
      { role: "user", content: "Please generate a resume that naturally includes relevant keywords from the job description and highlights my matching experience and skills, formatted in Markdown." }
    ]
  end
end
