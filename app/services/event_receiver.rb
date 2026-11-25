# Stores an incoming event once per (source, idempotency key).
class EventReceiver
  Result = Data.define(:status, :event)

  def initialize(source)
    @source = source
  end

  def call(event_type:, idempotency_key:, payload:)
    event = @source.events.new(event_type:, idempotency_key:, payload:, received_at: Time.current)
    return Result.new(:invalid, event) unless event.valid?

    event.save!
    Result.new(:created, event)
  rescue ActiveRecord::RecordNotUnique
    resolve_repeat(event_type:, idempotency_key:, payload:)
  end

  private

  def resolve_repeat(event_type:, idempotency_key:, payload:)
    existing = @source.events.find_by!(idempotency_key:)
    same = existing.payload == payload && existing.event_type == event_type
    Result.new(same ? :duplicate : :conflict, existing)
  end
end
