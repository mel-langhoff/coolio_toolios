# app/services/street_cred_scraper_service.rb
require 'nokogiri'
require 'open-uri'
require 'json'
require_relative 'company_name_extractor_service'
require 'openai'

class StreetCredScraperService
  BASE_KEYWORDS = %w[
    Ruby Rails SQL Docker Git REST_API HTML CSS JSON
    Agile Scrum Kanban SDLC OOP Postgres PostgreSQL Heroku
    APIs Testing RSpec Automation Optimization Debugging QA
    Teamwork Leadership Collaboration Communication Management
    Problem-solving Strategy Stakeholders Deliverables Deadlines
    SAP ERP Integration Cloud Migration
    Project Manager Consultant Developer Engineer Analyst
    Backend Fullstack
    Spanish Bilingual
    Teaching Training Mentorship
  ].freeze

  def initialize(url)
    @url = url
  end

  def cut_product
    html = URI.open(@url).read
    doc  = Nokogiri::HTML(html)

    title       = doc.at('title')&.text&.strip || "Untitled Job"
    company     = CompanyNameExtractorService.new(html).extract
    description = fetch_job_description_text(@url)

    found_keywords = BASE_KEYWORDS.select do |kw|
      doc.at('body')&.text&.downcase&.include?(kw.downcase)
    end

    ai_keywords = enhance_keywords_with_openai(description, found_keywords)

    job = {
      title: title,
      url: @url,
      company: company,
      description: description,
      keywords: (found_keywords + ai_keywords).uniq
    }

    summarized_job = summarize_with_openai(job)
    [job.merge(summarized_job)]
  rescue => e
    puts "Error scraping: #{e.message}"
    []
  end

  private

  def fetch_job_description_text(job_url)
    html = URI.open(job_url)
    doc  = Nokogiri::HTML(html)
    description_node = doc.at_css('.job-description') ||
                       doc.at_css('.description') ||
                       doc.at('body')
    description_node ? description_node.text.strip : ""
  rescue => e
    puts "Description scrape error: #{e.message}"
    ""
  end

  # 🪄 Enhance keywords using OpenAI (find implied & semantic matches)
  def enhance_keywords_with_openai(description, found_keywords)
    return [] if description.to_s.strip.empty?

    client = OpenAI::Client.new
    prompt = <<~PROMPT
      Given this job posting text:

      #{description}

      And these extracted keywords:

      #{found_keywords.join(', ')}

      Suggest additional relevant keywords, technologies, and soft skills implied by the posting
      (for example: 'collaboration' → 'teamwork', 'scaling' → 'performance optimization').
      Return them as a comma-separated list.
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        temperature: 0.4,
        messages: [
          { role: "system", content: "You are a professional keyword extraction assistant." },
          { role: "user", content: prompt }
        ]
      }
    )

    ai_text = response.dig("choices", 0, "message", "content") || ""
    ai_text.split(/,\s*/).map(&:strip).reject(&:empty?)
  rescue => e
    puts "Keyword enhancement error: #{e.message}"
    []
  end

  # 🧠 Summarize job posting using OpenAI
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
        model: "gpt-4o-mini",
        temperature: 0.4,
        messages: [
          { role: "system", content: "You are a professional job description summarizer." },
          { role: "user", content: prompt }
        ]
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  rescue => e
    puts "OpenAI summary error: #{e.message}"
    {}
  end
end
