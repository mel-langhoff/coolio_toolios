require 'rails_helper'

RSpec.describe StreetCredScraperService, type: :service do
  let(:url) { "https://jobs.lever.co/nava/441141bf-c935-490b-a57c-0aeb8dfc9099" }
  let(:service) { described_class.new(url) }

  describe '#cut_product', :vcr do
    it 'returns an array of job listings' do
      results = service.cut_product
# require 'pry'; binding.pry
      expect(results).to be_an(Array)
      expect(results.size).to be > 0
    end

    it 'each job listing has a title, url, and keywords keys' do
      results = service.cut_product
      first_job = results.first

      expect(first_job).to have_key(:title)
      expect(first_job).to have_key(:url)
      expect(first_job).to have_key(:keywords)
    end

    it 'keywords array contains only keywords from the predefined list' do
      results = service.cut_product
      first_job = results.first

      expect(first_job[:keywords]).to all(be_in(StreetCredScraperService::KEYWORDS))
    end

    it 'job title and url are non-empty strings' do
      results = service.cut_product
      first_job = results.first

      expect(first_job[:title]).to be_a(String)
      expect(first_job[:title]).not_to be_empty

      expect(first_job[:url]).to be_a(String)
      expect(first_job[:url]).not_to be_empty
    end
  end
end
