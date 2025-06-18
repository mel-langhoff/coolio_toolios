require 'rails_helper'

RSpec.describe "ProfessionalApiService", type: :service do

  it "#conn" do
    service = ProfessionalApiService.new
    connection = service.conn

    expect(connection).to be_an_instance_of Faraday::Connection
  end

    it "#get_url", :vcr do
      service = ProfessionalApiService.new      
      url = "/api/v0/experiences"
      service = ProfessionalApiService.new
      parsed_json = service.get_url(url)

      expect(parsed_json).to be_an Array
      expect(parsed_json.first[:id]).to eq 1
      expect(parsed_json.first[:title]).to eq("Private Tutor")
  end

  describe '#get_url', :vcr do
    it 'returns parsed JSON data from the given URL' do
      service = ProfessionalApiService.new
      url = "/api/v0/experiences"
      parsed_json = service.get_url(url)

      expect(parsed_json).to be_an(Array)
      expect(parsed_json.first[:id]).to eq(1)
      expect(parsed_json.first[:title]).to eq("Private Tutor")
    end
  end

  describe '#skills', :vcr do
    it 'fetches a list of skills from the API' do
      service = ProfessionalApiService.new
      skills = service.get_url("/api/v0/skills")

      expect(skills).to be_an(Array)
      expect(skills.first).to have_key(:name) if skills.any?
    end
  end

  describe '#experiences', :vcr do
    it 'fetches a list of experiences from the API' do
      service = ProfessionalApiService.new
      experiences = service.get_url("/api/v0/experiences")

      expect(experiences).to be_an(Array)
      expect(experiences.first).to have_key(:title) if experiences.any?
    end
  end

  describe '#projects', :vcr do
    it 'fetches a list of projects from the API' do
      service = ProfessionalApiService.new
      projects = service.get_url("/api/v0/projects")

      expect(projects).to be_an(Array)
      expect(projects.first).to have_key(:name) if projects.any?
    end
  end
end
