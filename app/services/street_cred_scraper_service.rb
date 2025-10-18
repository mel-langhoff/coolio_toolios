require "httparty"
require "nokogiri"
require "ferrum"
require "json"
require_relative "company_name_extractor_service"
require "openai"

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

  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "\
                "AppleWebKit/537.36 (KHTML, like Gecko) "\
                "Chrome/120.0 Safari/537.36"

  def initialize(url)
    @url = url
  end

  def cut_product
    html = fetch_html

    doc = Nokogiri::HTML(html)
    title       = doc.at("title")&.text&.strip || "Untitled Job"
    company     = CompanyNameExtractorService.new(html).extract
    description = extract_description(doc)

    found_keywords = BASE_KEYWORDS.select do |kw|
      doc.at("body")&.text&.downcase&.include?(kw.downcase)
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

  # 🔹 Step 1: Fetch HTML (fallback to Ferrum for JS-heavy pages)
  def fetch_html
    html = fast_fetch
    return html unless needs_render?(html)

    puts "⚙️ Falling back to Ferrum for full JS render..."
    render_with_ferrum
  end

  def fast_fetch
    HTTParty.get(@url, headers: { "User-Agent" => USER_AGENT }).body
  rescue
    ""
  end

  def needs_render?(html)
    html.nil? ||
      html.strip.length < 500 ||
      html.match?(/<script|window\.__INITIAL_STATE__|webpackJsonp|__NEXT_DATA__/)
  end

  def render_with_ferrum
    browser = Ferrum::Browser.new(headless: true, browser_options: { "no-sandbox" => nil })
    browser.goto(@url)
    sleep 2
    html = browser.body
    browser.quit
    html
  rescue => e
    browser&.quit
    puts "Ferrum render error: #{e.message}"
    ""
  end

  # 🔹 Step 2: Extract job description text
  def extract_description(doc)
    selectors = [
      "section.job_description",
      "div.job_description",
      "div.jobDescriptionSection",
      "div.jobDesc",
      "div.job-body",
      "article",
      "main",
      "body"
    ]
    node = selectors.map { |s| doc.at_css(s) }.compact.first
    text = node ? node.text.strip : ""
    text.gsub(/\s+/, " ").strip
  rescue
    ""
  end

  # 🔹 Step 3: AI Keyword enhancement
  def enhance_keywords_with_openai(description, found_keywords)
    return [] if description.to_s.strip.empty?

    client = OpenAI::Client.new
    prompt = <<~PROMPT
      Given this job posting text:

      #{description}

      And these extracted keywords:

      #{found_keywords.join(', ')}

      Suggest 10–15 additional relevant keywords, technologies, and soft skills implied by the posting.
      Example: 'collaboration' → 'teamwork', 'scaling' → 'performance optimization'.
      Return them as a comma-separated list only.
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

  # 🔹 Step 4: Summarize with OpenAI
  def summarize_with_openai(job)
    client = OpenAI::Client.new

    prompt = <<~PROMPT
      Summarize this job post as JSON with keys:
      - title
      - company
      - responsibilities (as bullet list)
      - skills_required (as bullet list)
      - tone (e.g., technical, corporate, energetic)
      - summary (1–2 sentences summarizing focus)
      === JOB POST TEXT ===
      #{job[:description]}
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        temperature: 0.4,
        messages: [
          { role: "system", content: "You are a professional job summarizer." },
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


# require "nokogiri"
# require "open-uri"
# require "json"
# require_relative "company_name_extractor_service"
# require "openai"

# class StreetCredScraperService
#   BASE_KEYWORDS = %w[
#     Ruby Rails SQL Docker Git REST_API HTML CSS JSON
#     Agile Scrum Kanban SDLC OOP Postgres PostgreSQL Heroku
#     APIs Testing RSpec Automation Optimization Debugging QA
#     Teamwork Leadership Collaboration Communication Management
#     Problem-solving Strategy Stakeholders Deliverables Deadlines
#     SAP ERP Integration Cloud Migration
#     Project Manager Consultant Developer Engineer Analyst
#     Backend Fullstack
#     Spanish Bilingual
#     Teaching Training Mentorship
#   ].freeze

#   def initialize(url)
#     @url = url
#   end

#   def cut_product
#     html = URI.open(@url, "User-Agent" => "Mozilla/5.0").read
#     doc  = Nokogiri::HTML(html)

#     title       = doc.at("title")&.text&.strip || "Untitled Job"
#     company     = CompanyNameExtractorService.new(html).extract
#     description = fetch_job_description_text(doc)

#     found_keywords = BASE_KEYWORDS.select do |kw|
#       doc.at("body")&.text&.downcase&.include?(kw.downcase)
#     end

#     ai_keywords = enhance_keywords_with_openai(description, found_keywords)

#     job = {
#       title: title,
#       url: @url,
#       company: company,
#       description: description,
#       keywords: (found_keywords + ai_keywords).uniq
#     }

#     summarized_job = summarize_with_openai(job)
#     [job.merge(summarized_job)]
#   rescue => e
#     puts "Error scraping: #{e.message}"
#     []
#   end

#   private

#   # 🧠 Smarter text extraction for ZipRecruiter, Indeed, LinkedIn, etc.
#   def fetch_job_description_text(doc)
#     possible_selectors = [
#       "section.job_description",
#       "div.job_description",
#       "div.jobDescriptionSection",
#       "div.jobDesc",
#       "div.job-body",
#       "article",
#       "main",
#       "body"
#     ]

#     node = possible_selectors.map { |s| doc.at_css(s) }.compact.first
#     text = node ? node.text.strip : ""

#     # Clean up whitespace and nonprintable chars
#     text.gsub(/\s+/, " ").strip
#   rescue => e
#     puts "Description scrape error: #{e.message}"
#     ""
#   end

#   # 🪄 Enhance keywords using OpenAI
#   def enhance_keywords_with_openai(description, found_keywords)
#     return [] if description.to_s.strip.empty?

#     client = OpenAI::Client.new
#     prompt = <<~PROMPT
#       Given this job posting text:

#       #{description}

#       And these extracted keywords:

#       #{found_keywords.join(', ')}

#       Suggest 10–15 additional relevant keywords, technologies, and soft skills implied by the posting
#       (for example: 'collaboration' → 'teamwork', 'scaling' → 'performance optimization').
#       Return them as a comma-separated list only, no extra text.
#     PROMPT

#     response = client.chat(
#       parameters: {
#         model: "gpt-4o-mini",
#         temperature: 0.4,
#         messages: [
#           { role: "system", content: "You are a professional keyword extraction assistant." },
#           { role: "user", content: prompt }
#         ]
#       }
#     )

#     ai_text = response.dig("choices", 0, "message", "content") || ""
#     ai_text.split(/,\s*/).map(&:strip).reject(&:empty?)
#   rescue => e
#     puts "Keyword enhancement error: #{e.message}"
#     []
#   end

#   # ✍️ Summarize job posting
#   def summarize_with_openai(job)
#     client = OpenAI::Client.new

#     prompt = <<~PROMPT
#       Summarize this job post as a JSON object with the following keys:
#       - title
#       - company
#       - responsibilities (as a short bullet list)
#       - skills_required (as a bullet list)
#       - tone (technical, corporate, energetic, etc.)
#       - summary (1–2 sentences describing the role focus and priorities)

#       === JOB POST TEXT ===
#       #{job[:description]}
#     PROMPT

#     response = client.chat(
#       parameters: {
#         model: "gpt-4o-mini",
#         temperature: 0.4,
#         messages: [
#           { role: "system", content: "You are a professional job summarizer." },
#           { role: "user", content: prompt }
#         ]
#       }
#     )

#     JSON.parse(response.dig("choices", 0, "message", "content"))
#   rescue => e
#     puts "OpenAI summary error: #{e.message}"
#     {}
#   end
# end
