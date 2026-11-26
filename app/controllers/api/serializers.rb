module Api
  # Explicit allow-lists, so new columns (and secrets) never leak by default.
  module Serializers
    module_function

    def source(source)
      { id: source.id, name: source.name, created_at: source.created_at }
    end

    def subscription(subscription)
      subscription.slice(:id, :source_id, :url, :event_filter, :active, :created_at)
    end

    def event(event)
      event.slice(:id, :source_id, :event_type, :idempotency_key, :received_at)
    end

    def event_detail(event)
      event(event).merge(
        payload: JSON.parse(event.payload),
        deliveries: event.deliveries.map do |delivery|
          delivery(delivery).merge(attempts: delivery.delivery_attempts.sort_by(&:number).map { |attempt| attempt(attempt) })
        end
      )
    end

    def delivery(delivery)
      delivery.slice(:id, :event_id, :subscription_id, :status, :attempts_count, :next_attempt_at, :updated_at)
    end

    def attempt(attempt)
      attempt.slice(:number, :response_code, :error, :duration_ms, :created_at)
    end
  end
end
