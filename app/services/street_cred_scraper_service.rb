require 'nokogiri'
require 'open-uri'
require_relative 'company_name_extractor_service'

class StreetCredScraperService
  KEYWORDS = %w[
    Ruby Rails JavaScript React SQL AWS Docker Kubernetes Python Git REST API
    communication teamwork "problem solving" leadership collaboration
    experience responsibilities requirements qualifications projects deliverables deadlines
    developed designed implemented managed optimized automated tested
    engineer developer manager consultant analyst company
  ].freeze

  def initialize(url)
    @url = url
  end

  def cut_product
    html = URI.open(@url).read
    doc = Nokogiri::HTML(html)

    title = doc.at('title')&.text&.strip || "Untitled Job"
    company = CompanyNameExtractorService.new(html).extract
    description = fetch_job_description_text(@url)
    found_keywords = KEYWORDS.select { |kw| doc.at('body')&.text&.downcase&.include?(kw.downcase) }

    job = {
      title: title,
      url: @url,
      company: company,
      description: description,
      keywords: found_keywords
    }

    summarized_job = summarize_with_openai(job)

    [job.merge(summarized_job)]
  rescue => e
    puts "Error scraping: #{e.message}"
    []
  end

  require 'openai'

  def summarize_with_openai(job)
    client = OpenAI::Client.new

    prompt = <<~PROMPT
      Summarize this job post as a JSON object with the following keys:
      - title
      - company
      - responsibilities (as a bullet list)
      - skills_required (as a bullet list)
      - tone (e.g. technical, casual, energetic, corporate)
      - summary (1–2 sentences describing the role)

      === JOB POST TEXT ===
      #{job[:description]}
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-4",
        temperature: 0.4,
        messages: [
          { role: "system", content: "You are a professional job description summarizer." },
          { role: "user", content: prompt }
        ]
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  rescue => e
    puts "OpenAI error: #{e.message}"
    {}
  end

  private

  def fetch_job_description_text(job_url)
    html = URI.open(job_url)
    doc = Nokogiri::HTML(html)
    # Adjust selector to the job description container on the job page
    description_node = doc.at_css('.job-description') || doc.at_css('.description') || doc.at('body')
    description_node ? description_node.text.strip : ""
  rescue
    ""
  end
end

