# Safety net: the delivery rows are the source of truth, so lost jobs and dead workers are repaired here.
class SweepDeliveriesJob < ApplicationJob
  OVERDUE_AFTER = 1.minute
  STUCK_AFTER = 10.minutes

  def perform
    release_stuck
    Delivery.where(status: "pending", next_attempt_at: ..OVERDUE_AFTER.ago).find_each do |delivery|
      DeliverJob.perform_later(delivery.id)
    end
  end

  private

  def release_stuck
    stuck = Delivery.where(status: "delivering", claimed_at: ..STUCK_AFTER.ago)
    stuck.where("attempts_count >= attempt_limit")
         .update_all(status: "dead", claimed_at: nil, updated_at: Time.current)
    # next_attempt_at is already in the past, so released rows are picked up as overdue.
    stuck.update_all(status: "pending", claimed_at: nil, updated_at: Time.current)
  end
end
