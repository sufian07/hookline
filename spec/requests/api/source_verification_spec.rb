require "rails_helper"

RSpec.describe "Sources API verification scheme" do
  it "creates a Stripe-signed source and reports its scheme" do
    post "/api/sources", params: { name: "Stripe", signing_secret: "whsec_x", verification: "stripe" },
                         headers: api_headers, as: :json

    expect(response).to have_http_status(:created)
    expect(json_body).to include("verification" => "stripe")

    get "/api/sources/#{json_body['id']}", headers: api_headers
    expect(json_body).to include("verification" => "stripe")
  end

  it "rejects an unknown scheme" do
    post "/api/sources", params: { name: "X", signing_secret: "y", verification: "github" }, headers: api_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end
end
