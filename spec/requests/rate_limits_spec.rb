require "rails_helper"

RSpec.describe "Rate limits" do
  it "limits ingest per source token" do
    RateLimits::INGEST_PER_MINUTE.times { post "/in/some-token", params: "{}" }
    expect(response).to have_http_status(:not_found)

    post "/in/some-token", params: "{}"
    expect(response).to have_http_status(:too_many_requests)

    post "/in/other-token", params: "{}"
    expect(response).to have_http_status(:not_found)
  end

  it "limits API calls per token, and allows them again after a minute" do
    RateLimits::API_PER_MINUTE.times { get "/api/session", headers: api_headers }

    get "/api/session", headers: api_headers
    expect(response).to have_http_status(:too_many_requests)
    expect(json_body).to include("error" => "rate limit exceeded")

    travel 61.seconds
    get "/api/session", headers: api_headers
    expect(response).to have_http_status(:ok)
  end
end
