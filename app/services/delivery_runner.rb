class DeliveryRunner
  def initialize(sender: HttpSender.new, jitter: -> { rand })
    @sender = sender
    @jitter = jitter
  end

  def call(delivery)
    return unless delivery.claim

    started = monotonic_ms
    result = send_request(delivery)
    return unless record(delivery, result, monotonic_ms - started)

    delivery.reload
    DeliverJob.set(wait_until: delivery.next_attempt_at).perform_later(delivery.id) if delivery.status == "pending"
  end

  private

  def send_request(delivery)
    subscription = delivery.subscription
    @sender.post(subscription.url, body: delivery.event.payload, headers: headers_for(delivery, subscription))
  end

  def headers_for(delivery, subscription)
    timestamp = Time.current.to_i.to_s
    {
      "Content-Type" => "application/json",
      "X-Hookline-Event" => delivery.event.event_type,
      "X-Hookline-Delivery" => delivery.id.to_s,
      "X-Hookline-Timestamp" => timestamp,
      "X-Hookline-Signature" => WebhookSignature.sign(
        secret: subscription.signing_secret, timestamp:, body: delivery.event.payload
      )
    }
  end

  def record(delivery, result, duration_ms)
    Delivery.transaction do
      delivery.delivery_attempts.create!(
        number: delivery.attempts_count, response_code: result.code, error: result.error, duration_ms:
      )
      delivery.finish(result, jitter: @jitter.call)
    end
  end

  def monotonic_ms
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
  end
end
