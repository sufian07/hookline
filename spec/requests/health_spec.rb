require "rails_helper"

RSpec.describe "Health" do
  it "reports that the app is up" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
