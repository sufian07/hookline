# Development and test use fixed, non-secret keys. Production must provide real ones.
Rails.application.configure do
  fetch = lambda do |name|
    Rails.env.production? ? ENV.fetch(name) : ENV.fetch(name, "insecure-local-only-#{name.downcase}")
  end

  config.active_record.encryption.primary_key = fetch.call("ENCRYPTION_PRIMARY_KEY")
  config.active_record.encryption.deterministic_key = fetch.call("ENCRYPTION_DETERMINISTIC_KEY")
  config.active_record.encryption.key_derivation_salt = fetch.call("ENCRYPTION_KEY_DERIVATION_SALT")
end
