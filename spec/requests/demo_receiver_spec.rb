require "rails_helper"

RSpec.describe "POST /demo/receiver" do
  it "does not exist outside demo mode" do
    post "/demo/receiver", params: "{}"

    expect(response).to have_http_status(:not_found)
  end

  it "accepts most deliveries and fails some, so retries are visible", :demo_mode do
    allow(DemoReceiver).to receive(:status_for).and_return(200, 503)

    post "/demo/receiver", params: "{}"
    expect(response).to have_http_status(:ok)

    post "/demo/receiver", params: "{}"
    expect(response).to have_http_status(:service_unavailable)
  end
end
