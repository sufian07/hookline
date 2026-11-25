class CreateIngestTables < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :token_digest, null: false, index: { unique: true }
      t.text :signing_secret, null: false
      t.timestamps
    end

    create_table :events do |t|
      t.references :source, null: false, foreign_key: true, index: false
      t.string :idempotency_key, null: false
      t.string :event_type, null: false
      t.text :payload, null: false
      t.datetime :received_at, null: false
      t.index [ :source_id, :idempotency_key ], unique: true
    end
  end
end
