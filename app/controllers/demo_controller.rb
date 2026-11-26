# Stand-in subscriber for the public demo. It answers like a flaky receiver, so retries,
# backoff and dead letters are visible without sending traffic anywhere else.
class DemoController < ApplicationController
  rate_limit to: 600, within: 1.minute, name: "demo-receiver", store: RateLimits.store

  def receive
    return head :not_found unless Rails.configuration.x.demo_mode

    head DemoReceiver.status_for(rand)
  end
end
