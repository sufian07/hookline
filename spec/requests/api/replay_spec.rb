require "rails_helper"

RSpec.describe "POST /api/deliveries/:id/replay" do
  let(:source) { create_source }
  let!(:delivery) do
    create_subscription(source)
    receive_event(source).deliveries.sole
  end

  def replay
    post "/api/deliveries/#{delivery.id}/replay", headers: api_headers
  end

  it "puts a dead delivery back in the queue with a fresh set of attempts" do
    delivery.update!(status: "dead", attempts_count: Delivery::MAX_ATTEMPTS)

    expect { replay }.to have_enqueued_job(DeliverJob).with(delivery.id)
    expect(response).to have_http_status(:accepted)
    expect(delivery.reload).to have_attributes(status: "pending", attempt_limit: Delivery::MAX_ATTEMPTS * 2)
  end

  it "can resend a delivered one" do
    delivery.update!(status: "delivered", attempts_count: 1)
    replay

    expect(delivery.reload.status).to eq("pending")
  end

  it "refuses while the delivery is still pending or in flight" do
    %w[pending delivering].each do |status|
      delivery.update!(status:)

      expect { replay }.not_to have_enqueued_job(DeliverJob)
      expect(response).to have_http_status(:conflict)
    end
  end
end
