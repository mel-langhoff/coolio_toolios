require 'rails_helper'

RSpec.describe Hustle, type: :model do
  before :each do
    @hustle = Hustle.new(
      job_title: "Backend Developer",
      company: "Bitchin Company",
      job_url: "https://example.com/job/123",
      resume: {
        contact: { name: "Melissa Langhoff", email: "mel@example.com" },
        skills: ["Ruby", "Rails"]
      }
    )
  end

  describe "validations" do
    it { should validate_presence_of :job_title }
    it { should validate_presence_of :job_url }
    it { should validate_presence_of :resume }
  end
end