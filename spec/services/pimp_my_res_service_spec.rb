require 'rails_helper'

RSpec.describe "PimpMyResService", type: :service do
  describe "GET /new" do
    xit "returns http success" do
      get "/pimp_my_res"
      expect(response).to have_http_status(:success)
    end
  end

end
