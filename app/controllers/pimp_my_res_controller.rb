class PimpMyResController < ApplicationController

  def new
  
  end

  def show
    # Assuming you have the resume draft stored in some variable, e.g.:
    @resume_markdown = params[:resume_markdown] || "No resume data available."
  end

  def create
    jobs_url = params[:job_posting_url] || "https://default.jobs.url"

    # Call your internal API for user data
    professional_data = {
      skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
      experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
      projects: ProfessionalApiService.new.get_url("/api/v0/projects"),
    }

    # prints json
      # puts JSON.pretty_generate(professional_data)

    # Scrape job data (you can tweak this to return useful values)
    @scraped_jobs = StreetCredScraperService.new(jobs_url).cut_product
        puts "Scraped jobs: #{@scraped_jobs}"


    messages = build_messages(professional_data, @scraped_jobs)
    openai = OpenAiService.new
    result = openai.chat_completion(messages: messages)


    if result[:choices].present?
      @resume_draft = result[:choices][0][:message][:content]
      @resume_markdown = @resume_draft # you can process this separately if needed

      # Extract some optional metadata from scraped_jobs
      job_title = scraped_jobs.first["title"] rescue "Unknown Title"
      # from user input
      jobs_url = params[:job_posting_url]
      # jobs_url = scraped_jobs.first["url"]
      company = @scraped_jobs.first["company"] rescue "Unknown Company"
      description = @scraped_jobs.first["description"] rescue "No description provided."

      # Save to Hustle table
      Rails.logger.info "Creating hustle record..."
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
    Rails.logger.info "Hustle created with ID: #{@hustle.id}"
      if @hustle.save
        Rails.logger.info "Hustle saved!"
      else
        Rails.logger.error "Hustle failed: #{@hustle.errors.full_messages.join(", ")}"
      end

      render :show
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
      { role: "user", content: "What is the name of the company hiring for this role?\n\n#{body_text}" },
      { role: "user", content: "Here are some job listings I want to tailor my resume for:\n#{scraped_jobs.to_json}" },
      { role: "user", content: "Please generate a resume for professional experience and skills resume draft and also plug in key words from the posting in the resume and in markdown format that highlights my skills and experiences aligned with the job listings." }
    ]
  end
end
