# Fills an empty database with a believable history for the public demo:
# one source, two subscriptions to the demo receiver, and deliveries in every state.
class DemoSeeder
  SOURCE_NAME = "Demo shop".freeze
  EVENT_TYPES = %w[order.created order.paid order.refunded customer.updated].freeze
  EVENT_COUNT = 40
  FAILURES = [ [ 503, nil ], [ 500, nil ], [ nil, "Net::ReadTimeout" ] ].freeze

  def self.payload(index, event_type, random)
    { id: "demo_#{index}", type: event_type, amount: random.rand(500..25_000), currency: "NZD" }
  end

  def initialize(random: Random.new, now: Time.current, receiver_url: DemoReceiver.url)
    @random = random
    @now = now
    @receiver_url = receiver_url
  end

  def call
    return false if Source.exists?
    raise ArgumentError, "APP_URL or RENDER_EXTERNAL_URL is required for demo data" if @receiver_url.blank?

    Source.transaction do
      source = Source.create!(name: SOURCE_NAME, signing_secret: SecureRandom.hex(32))
      source.subscriptions.create!(url: @receiver_url)
      source.subscriptions.create!(url: "#{@receiver_url}?team=refunds", event_filter: "order.refunded")
      EVENT_COUNT.times { |index| seed_event(source, index) }
    end
    true
  end

  private

  def seed_event(source, index)
    event_type = EVENT_TYPES[index % EVENT_TYPES.size]
    event = source.events.create!(
      event_type:,
      idempotency_key: "demo-#{index}",
      payload: self.class.payload(index, event_type, @random).to_json,
      received_at: @now - ((EVENT_COUNT - index) * 4).minutes
    )
    source.subscriptions.for_event_type(event_type).each { |subscription| seed_delivery(event, subscription) }
  end

  def seed_delivery(event, subscription)
    status, outcomes = plan_outcomes
    delivery = event.deliveries.create!(
      subscription:, status:, attempts_count: outcomes.size,
      next_attempt_at: status == "pending" ? @now + Backoff.delay(outcomes.size, jitter: @random.rand) : event.received_at
    )
    record_attempts(delivery, event.received_at, outcomes)
  end

  def plan_outcomes
    roll = @random.rand
    if roll < 0.7
      [ "delivered", failures(@random.rand(0..2)) + [ [ 200, nil ] ] ]
    elsif roll < 0.85
      [ "pending", failures(@random.rand(1..3)) ]
    else
      [ "dead", failures(Delivery::MAX_ATTEMPTS) ]
    end
  end

  def failures(count)
    Array.new(count) { FAILURES.sample(random: @random) }
  end

  def record_attempts(delivery, started_at, outcomes)
    at = started_at
    outcomes.each.with_index(1) do |(code, error), number|
      delivery.delivery_attempts.create!(
        number:, response_code: code, error:, duration_ms: @random.rand(40..400), created_at: [ at, @now ].min
      )
      at += Backoff.delay(number, jitter: @random.rand)
    end
  end
end
