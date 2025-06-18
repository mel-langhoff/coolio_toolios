require 'rails_helper'

RSpec.describe "PimpMyRes", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/pimp_my_res/new"
      expect(response).to have_http_status(:success)
    end
  end

end
