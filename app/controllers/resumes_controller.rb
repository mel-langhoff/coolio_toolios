class ResumesController < ApplicationController
  
  fdef show
  @resume = Resume.find(params[:id]) # or however you load it

  respond_to do |format|
    format.html
    format.pdf do
      render pdf: "resume",
             template: "resumes/show.pdf.erb",
             layout: false,
             page_size: 'Letter',
             margin: { top: 5, bottom: 5, left: 10, right: 10 }
    end
  end

  def pdf
    @resume = { name: "Melissa Langhoff", ... } # or load from Hustle if saved
    render pdf: "melissa_langhoff_resume", template: "resumes/pdf", layout: false
  end

end
