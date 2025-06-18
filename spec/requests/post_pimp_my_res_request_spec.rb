require 'rails_helper'

RSpec.describe "PimpMyRes", type: :request do
  describe "POST /pimp_my_res" do
    let(:valid_url) { "https://jobs.lever.co/nava" }

    before do
      # Stub ProfessionalApiService calls to avoid external requests
      allow_any_instance_of(ProfessionalApiService).to receive(:get_url).with("/api/v0/skills").and_return([{name: "Ruby"}, {name: "Rails"}])
      allow_any_instance_of(ProfessionalApiService).to receive(:get_url).with("/api/v0/experiences").and_return([{id: 1, title: "Dev"}])
      allow_any_instance_of(ProfessionalApiService).to receive(:get_url).with("/api/v0/projects").and_return([{id: 1, name: "Project X"}])
      allow_any_instance_of(ProfessionalApiService).to receive(:get_url).with("/api/v0/personal_details").and_return({about_me: "I'm great!"})

      # Stub scraper service to return fake job listings
      allow_any_instance_of(StreetCredScraperService).to receive(:cut_product).and_return([
        { title: "Alliance Manager", url: "https://some.jobs.url/job/123", keywords: ["Ruby", "Rails"] }
      ])

      # Stub OpenAiService chat_completion call
      allow_any_instance_of(OpenAiService).to receive(:chat_completion).and_return({
        choices: [
          { message: { content: "Generated resume content here" } }
        ]
      })
    end

    it "processes the job URL, calls OpenAI, and returns the resume draft JSON" do
      post pimp_my_res_path, params: { job_posting_url: valid_url }

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)

      expect(json).to have_key("resume_draft")
      expect(json["resume_draft"]).to eq("Generated resume content here")
    end
  end
end
