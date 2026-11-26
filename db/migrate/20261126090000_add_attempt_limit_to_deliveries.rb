class AddAttemptLimitToDeliveries < ActiveRecord::Migration[8.1]
  def change
    # Raised on replay, so attempt numbers keep increasing and stay unique.
    add_column :deliveries, :attempt_limit, :integer, null: false, default: 8
  end
end
