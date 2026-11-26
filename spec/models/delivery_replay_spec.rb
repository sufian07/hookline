require "rails_helper"

RSpec.describe Delivery, "replay" do
  let(:delivery) do
    source = create_source
    create_subscription(source)
    EventReceiver.new(source).call(event_type: "t", idempotency_key: "k", payload: "{}")
    Delivery.last
  end

  before { freeze_time }

  it "keeps attempt numbers increasing after a replay" do
    delivery.update!(status: "dead", attempts_count: Delivery::MAX_ATTEMPTS)
    delivery.replay
    sender = instance_double(HttpSender, post: HttpSender::Result.new(code: 500, error: nil))

    DeliveryRunner.new(sender:, jitter: -> { 1.0 }).call(delivery)

    expect(delivery.delivery_attempts.last.number).to eq(Delivery::MAX_ATTEMPTS + 1)
    expect(delivery.reload.status).to eq("pending")
  end

  it "dead-letters again once the new attempts run out" do
    delivery.update!(status: "dead", attempts_count: Delivery::MAX_ATTEMPTS)
    delivery.replay
    delivery.update!(attempts_count: (Delivery::MAX_ATTEMPTS * 2) - 1)
    sender = instance_double(HttpSender, post: HttpSender::Result.new(code: 500, error: nil))

    DeliveryRunner.new(sender:, jitter: -> { 1.0 }).call(delivery)

    expect(delivery.reload.status).to eq("dead")
  end

  it "only one of two concurrent replays wins" do
    delivery.update!(status: "dead")
    stale = Delivery.find(delivery.id)

    expect(delivery.replay).to be(true)
    expect(stale.replay).to be(false)
  end
end
