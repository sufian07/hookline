require "rails_helper"

RSpec.describe "Events API" do
  let(:source) { create_source }

  it "pages through events newest first with a cursor" do
    events = 3.times.map { |n| receive_event(source, key: "evt-#{n}") }

    get "/api/events", params: { limit: 2 }, headers: api_headers
    expect(json_body["data"].pluck("id")).to eq([ events[2].id, events[1].id ])

    get "/api/events", params: { limit: 2, before: json_body["next_cursor"] }, headers: api_headers
    expect(json_body["data"].pluck("id")).to eq([ events[0].id ])
    expect(json_body["next_cursor"]).to be_nil
  end

  it "caps the page size" do
    get "/api/events", params: { limit: 10_000 }, headers: api_headers

    expect(response).to have_http_status(:ok)
    expect(Api::BaseController::MAX_LIMIT).to eq(100)
  end

  it "filters by source and event type" do
    receive_event(source, type: "order.paid", key: "a")
    refund = receive_event(source, type: "order.refunded", key: "b")
    receive_event(create_source(name: "Other"), type: "order.refunded", key: "c")

    get "/api/events", params: { source_id: source.id, event_type: "order.refunded" }, headers: api_headers

    expect(json_body["data"].pluck("id")).to eq([ refund.id ])
  end

  it "shows an event with its payload, deliveries and attempts" do
    subscription = create_subscription(source)
    event = receive_event(source, payload: '{"id":7}')
    delivery = event.deliveries.sole
    delivery.delivery_attempts.create!(number: 1, response_code: 500, duration_ms: 12)

    get "/api/events/#{event.id}", headers: api_headers

    expect(json_body).to include("payload" => { "id" => 7 }, "event_type" => "order.paid")
    expect(json_body["deliveries"].sole).to include("id" => delivery.id, "subscription_id" => subscription.id)
    expect(json_body["deliveries"].sole["attempts"].sole).to include("number" => 1, "response_code" => 500)
  end
end
