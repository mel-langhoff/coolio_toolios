require 'nokogiri'
require 'open-uri'
require_relative 'company_name_extractor_service'

class StreetCredScraperService
  KEYWORDS = %w[
    Ruby Rails JavaScript React SQL Docker Git REST API
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

    title = doc.at('title')&.text&.strip
    company = CompanyNameExtractorService.new(html).extract
    # company = "Bitchin Company"
    description = fetch_job_description_text(@url)
    found_keywords = KEYWORDS.select { |kw| doc.at('body')&.text&.downcase&.include?(kw.downcase) }

    [{
      title: title,
      url: @url,
      company: company,
      description: description,
      keywords: found_keywords
    }]
  rescue => e
    puts "Error scraping: #{e.message}"
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

