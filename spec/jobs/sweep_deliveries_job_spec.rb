require "rails_helper"

RSpec.describe SweepDeliveriesJob do
  let!(:delivery) do
    freeze_time
    source = create_source
    create_subscription(source)
    EventReceiver.new(source).call(event_type: "t", idempotency_key: "k", payload: "{}")
    Delivery.last
  end

  it "enqueues deliveries that are overdue, in case their job was lost" do
    delivery.update!(next_attempt_at: 2.minutes.ago)

    expect { described_class.perform_now }.to have_enqueued_job(DeliverJob).with(delivery.id)
  end

  it "leaves deliveries alone while their own job should still run" do
    expect { described_class.perform_now }.not_to have_enqueued_job(DeliverJob)
  end

  it "releases a delivery whose worker died, then enqueues it" do
    delivery.claim
    travel 11.minutes

    expect { described_class.perform_now }.to have_enqueued_job(DeliverJob).with(delivery.id)
    expect(delivery.reload.status).to eq("pending")
  end

  it "dead-letters a crashed delivery that has no attempts left" do
    delivery.update!(attempts_count: Delivery::MAX_ATTEMPTS - 1)
    delivery.claim
    travel 11.minutes
    described_class.perform_now

    expect(delivery.reload.status).to eq("dead")
  end

  it "does not touch a delivery still being worked on" do
    delivery.claim
    described_class.perform_now

    expect(delivery.reload.status).to eq("delivering")
  end
end
