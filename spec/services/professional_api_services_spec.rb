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
      parsed_json = service.get_url(url)

      expect(parsed_json).to be_an Array
      expect(parsed_json.first[:id]).to eq 1
      expect(parsed_json.first[:title]).to eq("Private Tutor")
  end


  # let(:base_url) { 'http://localhost:3000/api/v0' }


  # describe '.skills' do
  #   it 'fetches a list of skills from the API' do
  #     skills = ProfessionalApiService.skills
  #     expect(skills).to be_an(Array)
  #     expect(skills.first).to have_key('name') if skills.any?
  #   end
  # end

  # describe '.experiences' do
  #   it 'fetches a list of experiences from the API' do
  #     experiences = ProfessionalApi.experiences
  #     expect(experiences).to be_an(Array)
  #     expect(experiences.first).to have_key('title') if experiences.any?
  #   end
  # end

  # describe '.projects' do
  #   it 'fetches a list of projects from the API' do
  #     projects = ProfessionalApi.projects
  #     expect(projects).to be_an(Array)
  #     expect(projects.first).to have_key('name') if projects.any?
  #   end
  # end

  # describe '.personal_details' do
  #   it 'fetches personal details from the API' do
  #     personal_details = ProfessionalApi.personal_details
  #     expect(personal_details).to be_a(Hash)
  #     expect(personal_details).to have_key('about_me')
  #   end
  # end
end
