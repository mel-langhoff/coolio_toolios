require 'rails_helper'

RSpec.describe "Xzibits", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/xzibit/index"
      expect(response).to have_http_status(:success)
    end
  end

end
