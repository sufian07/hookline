require "rails_helper"

RSpec.describe "Subscriptions API" do
  let(:source) { create_source }

  it "creates a subscription and returns its signing secret once" do
    post "/api/sources/#{source.id}/subscriptions",
         params: { url: "https://receiver.example.com/hooks", event_filter: "order.paid" },
         headers: api_headers, as: :json

    expect(response).to have_http_status(:created)
    subscription = Subscription.find(json_body["id"])
    expect(json_body).to include("signing_secret" => subscription.signing_secret, "event_filter" => "order.paid")
  end

  it "rejects URLs that could never be delivered to" do
    [ "http://receiver.example.com", "https://user:pass@receiver.example.com", "not a url" ].each do |url|
      post "/api/sources/#{source.id}/subscriptions", params: { url: }, headers: api_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "lists a source's subscriptions without their secrets" do
    create_subscription(source)

    get "/api/sources/#{source.id}/subscriptions", headers: api_headers

    expect(json_body["data"].sole).to include("url" => "https://receiver.example.com/hooks", "active" => true)
    expect(json_body["data"].sole).not_to have_key("signing_secret")
  end

  it "pauses and resumes a subscription" do
    subscription = create_subscription(source)

    patch "/api/subscriptions/#{subscription.id}", params: { active: false }, headers: api_headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(subscription.reload.active).to be(false)
  end

  it "does not let the source or secret be changed" do
    subscription = create_subscription(source)
    other = create_source(name: "Other")

    patch "/api/subscriptions/#{subscription.id}",
          params: { source_id: other.id, signing_secret: "mine" }, headers: api_headers, as: :json

    expect(subscription.reload).to have_attributes(source_id: source.id)
    expect(subscription.signing_secret).not_to eq("mine")
  end
end
