class HustlesController < ApplicationController
  def index
    @hustles = Hustle.all
  end

  def show
    @hustle = Hustle.find_by(params[:id])
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
