require "rails_helper"

RSpec.describe EventReceiver do
  let(:source) { create_source }

  def receive_event
    described_class.new(source).call(event_type: "order.paid", idempotency_key: "evt-1", payload: "{}")
  end

  it "creates and enqueues one delivery per matching active subscription" do
    all = create_subscription(source)
    match = create_subscription(source, event_filter: "order.paid")
    create_subscription(source, event_filter: "order.refunded")
    create_subscription(source, active: false)
    create_subscription(create_source(name: "Other"))

    expect { receive_event }.to have_enqueued_job(DeliverJob).exactly(2).times
    expect(Delivery.pluck(:subscription_id)).to contain_exactly(all.id, match.id)
  end

  it "does not deliver a duplicate event again" do
    create_subscription(source)
    receive_event

    expect { receive_event }.not_to have_enqueued_job(DeliverJob)
    expect(Delivery.count).to eq(1)
  end
end
