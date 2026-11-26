require "rails_helper"

RSpec.describe "Deliveries API" do
  let(:source) { create_source }

  it "filters deliveries by status, so dead letters are easy to find" do
    create_subscription(source)
    dead = receive_event(source, key: "a").deliveries.sole
    receive_event(source, key: "b")
    dead.update!(status: "dead")

    get "/api/deliveries", params: { status: "dead" }, headers: api_headers

    expect(json_body["data"].pluck("id")).to eq([ dead.id ])
    expect(json_body["data"].sole).to include("status" => "dead", "event_id" => dead.event_id)
  end

  it "rejects an unknown status filter" do
    get "/api/deliveries", params: { status: "lost" }, headers: api_headers

    expect(response).to have_http_status(:bad_request)
  end
end
