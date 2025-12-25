require 'rails_helper'

RSpec.describe CompanyNameExtractorService do
  describe '#extract' do
    it 'can extract company name from meta tag' do
      html = <<~HTML
        <html>
          <head>
            <meta property="og:site_name" content="Test Company" />
            <title>Job Title at Test Company</title>
          </head>
          <body></body>
        </html>
      HTML

      service = CompanyNameExtractorService.new(html)
      expect(service.extract).to eq("Test Company")
    end

    it 'can extract company name from title' do
      html = <<~HTML
        <html>
          <head>
            <title>Job Title at ExampleCorp</title>
          </head>
          <body></body>
        </html>
      HTML

      service = CompanyNameExtractorService.new(html)
      expect(service.extract).to eq("ExampleCorp")
    end

    it 'has sad path testing for nil' do
      html = <<~HTML
        <html>
          <head>
            <title>Just a title without company</title>
          </head>
          <body></body>
        </html>
      HTML

      service = CompanyNameExtractorService.new(html)
      expect(service.extract).to eq("Unknown Company")
    end
  end
end
