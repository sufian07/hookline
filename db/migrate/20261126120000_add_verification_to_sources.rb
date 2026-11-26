class AddVerificationToSources < ActiveRecord::Migration[8.1]
  def change
    # How ingest checks a source's requests: Hookline's own headers, or Stripe-Signature.
    add_column :sources, :verification, :string, null: false, default: "hookline"
    add_check_constraint :sources, "verification IN ('hookline', 'stripe')", name: "sources_verification"
  end
end
