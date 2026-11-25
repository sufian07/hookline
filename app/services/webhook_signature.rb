# Pure functions: no I/O and no clock, so callers pass the time in.
module WebhookSignature
  REPLAY_WINDOW = 300

  module_function

  def sign(secret:, timestamp:, body:)
    "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
  end

  def valid?(secret:, timestamp:, body:, signature:, now:)
    return false unless timestamp.to_s.match?(/\A\d+\z/) && signature.present?
    return false if (now.to_i - timestamp.to_i).abs > REPLAY_WINDOW

    ActiveSupport::SecurityUtils.secure_compare(sign(secret:, timestamp:, body:), signature)
  end
end
