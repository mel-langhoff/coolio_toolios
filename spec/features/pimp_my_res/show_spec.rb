require "rails_helper"

RSpec.describe "Pimp My Res show page", type: :feature do
  it "displays the hustle details and generated resume" do
    # Create a Hustle record manually
    hustle = Hustle.create!(
      job_url: "https://example.com/job-posting",
      job_title: "Senior Rails Dev",
      company: "Coolio Corp",
      job_description: "Write APIs and scale the monolith.",
      resume: {
        "skills" => ["Rails", "APIs", "PostgreSQL"],
        "experiences" => ["Built stuff at previous companies"],
        "projects" => ["Coolio Toolios"],
        "generated_resume" => "# My Resume\n\n## Experience\nWorked at Coolio Corp."
      }
    )

    # Visit the show page
    visit pimp_my_res_show_path(hustle.id)

    # Expectations
    expect(page).to have_content("Finna get ya a job")
    expect(page).to have_content("Hustle for Senior Rails Dev at Coolio Corp")
    expect(page).to have_link("https://example.com/job-posting")
    expect(page).to have_content("Write APIs and scale the monolith.")
    expect(page).to have_content("My Resume") # from the markdown
    expect(page).to have_content("Worked at Coolio Corp.")
    expect(page).to have_link("Do it again")
  end
end
