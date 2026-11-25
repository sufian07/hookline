require "rails_helper"

RSpec.describe DeliveryRunner do
  let(:source) { create_source }
  let!(:subscription) { create_subscription(source) }
  let(:sender) { instance_double(HttpSender) }
  let!(:delivery) do
    freeze_time
    EventReceiver.new(source).call(event_type: "order.paid", idempotency_key: "evt-1", payload: '{"id":1}')
    Delivery.last
  end

  def run(code: 200, error: nil)
    allow(sender).to receive(:post).and_return(HttpSender::Result.new(code:, error:))
    described_class.new(sender:, jitter: -> { 1.0 }).call(delivery)
    delivery.reload
  end

  it "marks a successful delivery and records the attempt" do
    run

    expect(delivery).to have_attributes(status: "delivered", attempts_count: 1)
    expect(delivery.delivery_attempts.sole).to have_attributes(number: 1, response_code: 200, error: nil)
  end

  it "signs the payload with the subscription secret so receivers can verify it" do
    run

    expect(sender).to have_received(:post) do |url, body:, headers:|
      expect(url).to eq(subscription.url)
      expect(body).to eq('{"id":1}')
      expect(headers).to include("X-Hookline-Event" => "order.paid", "X-Hookline-Delivery" => delivery.id.to_s)
      expect(WebhookSignature.valid?(
        secret: subscription.signing_secret, timestamp: headers["X-Hookline-Timestamp"],
        body:, signature: headers["X-Hookline-Signature"], now: Time.current
      )).to be(true)
    end
  end

  it "schedules a retry after a failure" do
    expect { run(code: 500) }.to have_enqueued_job(DeliverJob).with(delivery.id).at(30.seconds.from_now)

    expect(delivery).to have_attributes(status: "pending", attempts_count: 1, next_attempt_at: 30.seconds.from_now)
  end

  it "records the error when there is no response" do
    run(code: nil, error: "Net::OpenTimeout")

    expect(delivery.delivery_attempts.sole).to have_attributes(response_code: nil, error: "Net::OpenTimeout")
  end

  it "dead-letters after the last allowed attempt" do
    delivery.update!(attempts_count: Delivery::MAX_ATTEMPTS - 1)

    expect { run(code: 500) }.not_to have_enqueued_job(DeliverJob)
    expect(delivery).to have_attributes(status: "dead", attempts_count: Delivery::MAX_ATTEMPTS)
  end

  it "does nothing when the delivery is not due yet" do
    delivery.update!(next_attempt_at: 1.minute.from_now)
    run

    expect(sender).not_to have_received(:post)
  end

  it "does nothing when the delivery is already finished" do
    2.times { run }

    expect(sender).to have_received(:post).once
  end

  it "lets only one of two workers claim the same delivery" do
    stale_copy = Delivery.find(delivery.id)

    expect(delivery.claim).to be(true)
    expect(stale_copy.claim).to be(false)
  end

  it "ignores a late result from a worker whose claim was taken over" do
    delivery.claim
    late = Delivery.find(delivery.id)
    Delivery.where(id: delivery.id).update_all(attempts_count: 2)

    late.finish(HttpSender::Result.new(code: 200, error: nil), jitter: 1.0)

    expect(delivery.reload.status).to eq("delivering")
  end
end
