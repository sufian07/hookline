module Builders
  def create_source(**attrs)
    Source.create!({ name: "Shop", signing_secret: "s3cret" }.merge(attrs))
  end

  def create_subscription(source, **attrs)
    source.subscriptions.create!({ url: "https://receiver.example.com/hooks" }.merge(attrs))
  end

  def signed_headers(body, secret: "s3cret", at: Time.current, type: "order.paid", key: "evt-1")
    timestamp = at.to_i.to_s
    {
      "CONTENT_TYPE" => "application/json",
      "X-Hookline-Timestamp" => timestamp,
      "X-Hookline-Signature" => WebhookSignature.sign(secret:, timestamp:, body:),
      "X-Hookline-Event" => type,
      "X-Hookline-Idempotency-Key" => key
    }
  end
end

RSpec.configure { |config| config.include Builders }
