require "rails_helper"

RSpec.describe "API authentication" do
  it "rejects a request without a token" do
    get "/api/sources"

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a wrong token" do
    get "/api/sources", headers: api_headers("wrong")

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects everything when no admin token is configured" do
    Rails.configuration.x.admin_token = nil

    get "/api/sources", headers: api_headers("")

    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts the admin token" do
    get "/api/sources", headers: api_headers

    expect(response).to have_http_status(:ok)
  end
end
