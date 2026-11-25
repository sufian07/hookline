class CreateDeliveryTables < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :source, null: false, foreign_key: true
      t.string :url, null: false
      t.string :event_filter
      t.text :signing_secret, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :deliveries do |t|
      t.references :event, null: false, foreign_key: true, index: false
      t.references :subscription, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :attempts_count, null: false, default: 0
      t.datetime :next_attempt_at, null: false
      t.datetime :claimed_at
      t.timestamps
      t.index [ :event_id, :subscription_id ], unique: true
      t.index [ :status, :next_attempt_at ]
      t.check_constraint "status IN ('pending', 'delivering', 'delivered', 'dead')", name: "deliveries_status"
    end

    create_table :delivery_attempts do |t|
      t.references :delivery, null: false, foreign_key: true, index: false
      t.integer :number, null: false
      t.integer :response_code
      t.string :error
      t.integer :duration_ms, null: false
      t.datetime :created_at, null: false
      t.index [ :delivery_id, :number ], unique: true
    end
  end
end
