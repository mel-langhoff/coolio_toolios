class PimpMyResController < ApplicationController
  def new
  end

  def create
    jobs_url = params[:job_posting_url] || "https://default.jobs.url"
    result = ResumePlugService.new(jobs_url: jobs_url).call

    if result[:error]
      render plain: "Error: #{result[:error]}", status: :bad_request
    else
      @hustle = result[:hustle]
      redirect_to pimp_my_res_show_path(@hustle.id)
    end
  end

  def show
    @hustle = Hustle.find(params[:id])
    @resume_markdown = @hustle.resume["generated_resume"]
  end
end
