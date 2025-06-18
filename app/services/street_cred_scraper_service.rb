require 'nokogiri'
require 'open-uri'

class StreetCredScraperService
  KEYWORDS = %w[
    Ruby Rails JavaScript React SQL AWS Docker Kubernetes Python Git REST API
    communication teamwork "problem solving" leadership collaboration
    experience responsibilities requirements qualifications projects deliverables deadlines
    developed designed implemented managed optimized automated tested
    engineer developer manager consultant analyst
  ].freeze

  def initialize(url)
    @url = url
  end

def cut_product
  html = URI.open(@url)
  doc = Nokogiri::HTML(html)

  # Extract entire text from the page body
  page_text = doc.at('body').text.downcase

  # Find keywords in the whole page text
  found_keywords = KEYWORDS.select { |kw| page_text.include?(kw.downcase) }

    [{
      title: title,
      url: link['href']
      keywords: found_keywords
    }]
  rescue OpenURI::HTTPError => e
    puts "⚠️ Failed to scrape #{@url}: #{e.message}"
    []
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
