require "rails_helper"

RSpec.describe "API roles" do
  let(:viewer_token) { "test-viewer-token" }
  let(:source) { create_source }

  before { Rails.configuration.x.viewer_token = viewer_token }
  after { Rails.configuration.x.viewer_token = nil }

  it "tells each token its role" do
    get "/api/session", headers: api_headers
    expect(json_body).to eq("role" => "admin")

    get "/api/session", headers: api_headers(viewer_token)
    expect(json_body).to eq("role" => "viewer")
  end

  it "lets a viewer read everything" do
    create_subscription(source)
    event = receive_event(source)

    [ "/api/sources", "/api/sources/#{source.id}", "/api/sources/#{source.id}/subscriptions",
      "/api/events", "/api/events/#{event.id}", "/api/deliveries" ].each do |path|
      get path, headers: api_headers(viewer_token)

      expect(response).to have_http_status(:ok), path
    end
  end

  it "refuses every write from a viewer" do
    subscription = create_subscription(source)
    delivery = receive_event(source).deliveries.sole
    delivery.update!(status: "dead")

    writes = [
      [ :post, "/api/sources", { name: "X", signing_secret: "y" } ],
      [ :post, "/api/sources/#{source.id}/subscriptions", { url: "https://r.example.com" } ],
      [ :patch, "/api/subscriptions/#{subscription.id}", { active: false } ],
      [ :post, "/api/deliveries/#{delivery.id}/replay", {} ]
    ]
    writes.each do |verb, path, params|
      send(verb, path, params:, headers: api_headers(viewer_token), as: :json)

      expect(response).to have_http_status(:forbidden), path
    end
    expect(subscription.reload.active).to be(true)
    expect(delivery.reload.status).to eq("dead")
  end

  it "grants nothing to a blank viewer token" do
    Rails.configuration.x.viewer_token = ""

    get "/api/session", headers: api_headers("")

    expect(response).to have_http_status(:unauthorized)
  end
end
