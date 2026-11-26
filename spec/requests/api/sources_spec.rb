require "rails_helper"

RSpec.describe "Sources API" do
  it "creates a source and returns its ingest token once" do
    post "/api/sources", params: { name: "Shop", signing_secret: "s3cret" }, headers: api_headers, as: :json

    expect(response).to have_http_status(:created)
    token = json_body.fetch("token")
    expect(Source.find_by_token(token)).to have_attributes(name: "Shop")
    expect(json_body).to include("ingest_path" => "/in/#{token}")
    expect(json_body).not_to have_key("signing_secret")
  end

  it "never shows the token again" do
    source = create_source

    get "/api/sources/#{source.id}", headers: api_headers

    expect(json_body).to include("id" => source.id, "name" => "Shop")
    expect(json_body.keys).not_to include("token", "token_digest", "signing_secret")
  end

  it "reports validation errors" do
    post "/api/sources", params: { name: "" }, headers: api_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_body["errors"]).to be_present
  end

  it "lists sources newest first" do
    first = create_source(name: "A")
    second = create_source(name: "B")

    get "/api/sources", headers: api_headers

    expect(json_body["data"].pluck("id")).to eq([ second.id, first.id ])
  end

  it "answers 404 for an unknown source" do
    get "/api/sources/0", headers: api_headers

    expect(response).to have_http_status(:not_found)
  end
end
