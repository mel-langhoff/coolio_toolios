require 'rails_helper'

RSpec.describe "XzibitService", type: :service do
  describe "GET /index" do
    xit "returns http success" do
      get "/xzibit"
      expect(response).to have_http_status(:success)
    end
  end

end
