# app/controllers/pimp_my_res_controller.rb
class PimpMyResController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new
  end

  def show
    @resume_markdown = params[:resume_markdown] || "No resume data available."
  end

  def create
    jobs_url = params[:job_posting_url] || "https://default.jobs.url"

    # 🔹 Fetch professional data from your internal Professional API
    # professional_data = {
    #   skills: ProfessionalApiService.new.get_url("/api/v0/skills"),
    #   experiences: ProfessionalApiService.new.get_url("/api/v0/experiences"),
    #   projects: ProfessionalApiService.new.get_url("/api/v0/projects")
    # }
    professional_data = ProfessionalFacade.new.get_professional_data

    # 🔹 Scrape job posting data
    @scraped_jobs = StreetCredScraperService.new(jobs_url).cut_product
    Rails.logger.info "Scraped jobs: #{@scraped_jobs.inspect}"

    # 🔹 Safely extract job body text
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

  # 🔹 Builds OpenAI prompt messages
  def build_messages(professional_data, scraped_jobs, body_text)
    [
      { role: "system", content: "You are a professional resume-writing assistant with over thirty years of experience in the IT recruiter field for Ruby on Rails developers and IT project management and technical project manager roles that optimizes for ATS (Applicant Tracking Systems) and includes keywords from words in job postings submitted to you by a user into their resumes and uses their skills and roles to craft new resumes. The user will submit details about themselves to you.." },
      { role: "user", content: "Here is my professional data including skills, experiences, projects, and personal details:\n#{professional_data.to_json}. Use them to craft or improve on a resume that will land me a job and that will get past and ATS so that I will land my resume in front of a human being's eyes." },
      { role: "user", content: "What is the name of the company hiring for this role?\n\n#{body_text} Find it." },
      { role: "user", content: "Craft a resume for me with all of this critera. Follow the format of this resume here mlanghoff@uwalumni.com  |  414-324-7291  |  Boulder, CO  |  [Portfolio](https://www.mel-langhoff.com/)  |  [Github](https://github.com/mel-langhoff)  |  [LinkedIn](https://www.linkedin.com/in/melissalanghoff/)  
---

**Relevant Professional Experience:**  
**Xcel Energy**  |  *Remote, July 2022 \- November 2022*  
IT Project Manager

* Developed and implemented new Agile project management systems, tools, and processes, reducing project lifecycles by 1-2 weeks and improving delivery timelines by 24%.

**Sling TV**  |  *Hybrid/Denver, CO, February 2022 \- May 2022*  
Program Manager

* Optimized IT and advertising projects using Agile, Scrum, and Kanban methodologies, resulting in a 20% productivity boost and improved project outcomes.

**Crocs**  |  *Niwot, CO, September 2019 \- April 2020*  
SAP Project Manager

* Led a 45-member cross-functional internal team and third-party vendors in migrating SAP environments to the SAP HANA Enterprise Cloud.  
* Crafted comprehensive testing schedules and cutover plans, ensuring seamless transitions and minimal downtime during go-live.

**Sovos Compliance**  |  *Atlanta, GA, April 2017 \- January 2019*  
Project Manager, Implementation Consultant, & Junior SAP FI Consultant

* Integrated SaaS SAP ERP solutions for Fortune 500 companies, including eInvoicing, eAccounting, and tax compliance software for LATAM countries and Mexico.  
* Created bilingual training materials and led training sessions, improving client satisfaction and reducing tax errors while enhancing operational efficiency.


**Projects:**   
**Personal Portfolio**, Solo Project  |  [Repository](https://github.com/mel-langhoff/resume)  |  [Demo Link](https://www.mel-langhoff.com/)  
A Ruby on Rails application hosted on Heroku that includes a resume, portfolio, and examples of frontend & backend skills, utilizing ActiveRecord, Bootstrap, Postman, RSpec, and Ruby gems.  
**Battleship**, Group Project  |  [Repository](https://github.com/mel-langhoff/battleship)  
A Ruby application that is a one player game of Battleship that is played in the Terminal.

**Education:**   
**Turing School of Software & Design  |**  *Remote, October 2023 \- September 2024*  
Backend Engineering Certificate  
**University of Wisconsin-Madison**  |  *Madison, WI, May 2016*  
Bachelor of Arts in Linguistics; Bachelor of Arts in Spanish

**Skills:**  
**Programming Languages & Methodologies:** ActiveRecord, CSS, HTML, JSON, Object-Oriented Programming, Ruby, Ruby on Rails, SQL, Test-Driven Development, XML  
**Tools & Technologies:** Adobe Creative Suite, APIs, Docker, Git, Google Suite, Heroku, Microsoft Office, PostgreSQL, Postman, Salesforce, WordPress  
**Workflow Tools:** Asana, Confluence, Github Projects, JIRA, Monday, Rally, ServiceNow, Slack, SharePoint, SmartSheet, Trello  
**Professional Skills:** Agile Project Management, Business Process Improvement, Change Management, Communication, Kanban, Leadership, QA Testing, Scrum, Software Development Life Cycle (SDLC), Stakeholder Management, Vendor Management  
**Spoken Languages:** Spanish \- bilingual in business and conversation  
**Interests:** Cooking, cycling, languages, literature, snowshoeing  and make the format a .docx file so I can edit it." }
      # { role: "user", content: "Please generate a resume that naturally includes relevant keywords from the job description and highlights my matching experience and skills, formatted in Markdown." }
    ]
  end
end
