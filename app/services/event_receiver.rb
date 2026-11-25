# Stores an incoming event once per (source, idempotency key) and fans it out to subscribers.
class EventReceiver
  Result = Data.define(:status, :event)

  def initialize(source)
    @source = source
  end

  def call(event_type:, idempotency_key:, payload:)
    event = @source.events.new(event_type:, idempotency_key:, payload:, received_at: Time.current)
    return Result.new(:invalid, event) unless event.valid?

    deliveries = store(event)
    deliveries.each { |delivery| DeliverJob.perform_later(delivery.id) }
    Result.new(:created, event)
  rescue ActiveRecord::RecordNotUnique
    resolve_repeat(event_type:, idempotency_key:, payload:)
  end

  private

  def store(event)
    Event.transaction(requires_new: true) do
      event.save!
      @source.subscriptions.for_event_type(event.event_type).map do |subscription|
        event.deliveries.create!(subscription:, next_attempt_at: event.received_at)
      end
    end
  end

  def resolve_repeat(event_type:, idempotency_key:, payload:)
    existing = @source.events.find_by!(idempotency_key:)
    same = existing.payload == payload && existing.event_type == event_type
    Result.new(same ? :duplicate : :conflict, existing)
  end
end
