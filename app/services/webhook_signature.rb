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

  # Stripe-Signature: t=<unix seconds>,v1=<hex HMAC-SHA256 of "t.body">, possibly several v1 values.
  def valid_stripe?(secret:, header:, body:, now:)
    pairs = header.to_s.split(",").map { |part| part.split("=", 2) }
    timestamp = pairs.find { |key, _| key == "t" }&.last
    candidates = pairs.select { |key, _| key == "v1" }.map(&:last).compact
    return false unless timestamp.to_s.match?(/\A\d+\z/) && candidates.any?
    return false if (now.to_i - timestamp.to_i).abs > REPLAY_WINDOW

    expected = sign(secret:, timestamp:, body:).delete_prefix("sha256=")
    candidates.any? { |candidate| ActiveSupport::SecurityUtils.secure_compare(expected, candidate) }
  end
end
