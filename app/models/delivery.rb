# pending -> delivering -> delivered | pending (retry) | dead
#
# Transitions are conditional UPDATEs, so two workers cannot both win one.
class Delivery < ApplicationRecord
  MAX_ATTEMPTS = 8
  STATUSES = %w[pending delivering delivered dead].freeze

  belongs_to :event
  belongs_to :subscription
  has_many :delivery_attempts, dependent: :destroy

  # Takes the delivery if it is due. The attempt number doubles as a fencing token.
  def claim
    now = Time.current
    won = self.class.where(id:, status: "pending", next_attempt_at: ..now).update_all(
      [ "status = 'delivering', claimed_at = ?, updated_at = ?, attempts_count = attempts_count + 1", now, now ]
    ) == 1
    reload if won
    won
  end

  # Returns false when another worker has taken over this delivery since the claim.
  def finish(result, jitter:)
    self.class.where(id:, status: "delivering", attempts_count:)
        .update_all(outcome(result, jitter).merge(claimed_at: nil, updated_at: Time.current)) == 1
  end

  private

  def outcome(result, jitter)
    if result.success?
      { status: "delivered" }
    elsif attempts_count >= MAX_ATTEMPTS
      { status: "dead" }
    else
      { status: "pending", next_attempt_at: Time.current + Backoff.delay(attempts_count, jitter:) }
    end
  end
end
