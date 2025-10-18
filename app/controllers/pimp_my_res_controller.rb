# app/controllers/pimp_my_res_controller.rb
class PimpMyResController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new
  end

  def show
    @resume_markdown = params[:resume_markdown] || "No resume data available."
  end

  def create
    job_url = params[:job_posting_url] || "https://default.jobs.url"

    # 🔹 Fetch professional data from your internal Professional API
    # professional_data = {
    #   skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
    #   experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
    #   projects: ProfessionalApiService.new.get_url("/api/v0/projects")
    # }
    professional_data = ProfessionalFacade.new.get_professional_data

    # 🔹 Scrape job posting data
    @scraped_job = StreetCredScraperService.new(job_url).cut_product
    Rails.logger.info "Scraped jobs: #{@scraped_job.inspect}"

    # 🔹 Safely extract job body text
    body_text = @scraped_job.first[:description] rescue "No description available."

    # 🔹 Build messages for OpenAI
    messages = build_messages(professional_data, @scraped_job, body_text)

    # 🔹 Send prompt to OpenAI
    openai = OpenAiService.new
    result = openai.chat_completion(messages: messages)

    if result[:choices].present?
      @resume_draft = result[:choices][0][:message][:content]
      @resume_markdown = @resume_draft

      # 🔹 Extract job metadata
      job_title   = @scraped_job.first[:title] rescue "Unknown Title"
      company     = @scraped_job.first[:company] rescue "Unknown Company"
      description = @scraped_job.first[:description] rescue "No description provided."

      # 🔹 Create Hustle record
      @hustle = Hustle.create!(
        job_url: job_url,
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

      # 🔹 Respond as HTML or JSON
      respond_to do |format|
        format.html { render :show }
        format.json do
          render json: {
            message: "✅ Resume generated and Hustle created successfully.",
            job: {
              title: job_title,
              company: company,
              description: description
            },
            resume: {
              markdown: @resume_markdown,
              professional_data: professional_data
            }
          }, status: :ok
        end
      end
    else
      error_message = result[:error] ? result[:error][:message] : "Unknown error from OpenAI"

      respond_to do |format|
        format.html { render plain: error_message, status: :bad_request }
        format.json { render json: { error: error_message }, status: :bad_request }
      end
    end
  rescue => e
    Rails.logger.error "💥 Error in PimpMyResController#create: #{e.message}"

    respond_to do |format|
      format.html { render plain: "Something went wrong: #{e.message}", status: 500 }
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  private

  def build_messages(professional_data, scraped_job, body_text)
    writing_sample = File.read(Rails.root.join("lib", "assets", "texts", "writing_sample.txt"))
    base_resume    = File.read(Rails.root.join("lib", "assets", "texts", "base_resume.md"))
    excluded_words = File.readlines(Rails.root.join("lib", "assets", "texts", "excluded_keywords.txt"), chomp: true)
    excluded_list  = excluded_words.join(', ')

    [
      { role: "system", content: "You are a professional resume-writing assistant with over thirty years of experience looking at, writing, and hiring people in the IT field for software developers, project managers, SAP, and anything else IT..." },
      { role: "user", content: "Here is a short writing sample that represents my tone, used punctuation, type of word usage and adjective and syntax choices, and overall type and cool and bitchin' style:\n\n#{writing_sample}, so please attempt to replicate as best as you can but nobody can beat the best, can they?" },
      { role: "user", content: "Here is my professional data including skills, experiences, projects, and personal details:\n#{professional_data.to_json}, so use these and emphasize them in the resume and really dig deep, but avoid using typical and stereotypical resume buzzwords but make it sound human, fancy, and 100% fuckin' bitchin'" },
      { role: "user", content: "Here is the job posting I want to tailor my resume for:\n#{scraped_job.to_json}" },
      { role: "user", content: "Use the following as my baseline resume format. Update it to match the job posting while keeping my tone and layout:\n\n#{base_resume}. Keep it so the resume is under one page. Alphabetize the skills and arrange the jobs in order by most recent the least recent. Avoid using the following words or phrases in the final text: #{excluded_list}. Keep the format exactly the same please! I love you ,chat!" }
    ]
  end




end
