class Event < ApplicationRecord
  belongs_to :source

  validates :idempotency_key, :event_type, presence: true, length: { maximum: 255 }
  validates :received_at, presence: true
  validate :payload_is_json

  private

  def payload_is_json
    JSON.parse(payload.to_s)
  rescue JSON::ParserError
    errors.add(:payload, "must be valid JSON")
  end
end
