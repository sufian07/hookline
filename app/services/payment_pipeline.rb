# Rebuilds the Stripe-to-Ledgerline pipeline from configuration: a Stripe-signed source
# at a fixed token (so Stripe's webhook URL never changes) and a subscription to
# Ledgerline. The free deployment loses its database on every restart, so this runs
# on every boot and is safe to repeat.
class PaymentPipeline
  SOURCE_NAME = "Stripe payments".freeze
  TOKEN_FORMAT = /\A[A-Za-z0-9_-]{24,128}\z/

  def self.from_env(env = ENV)
    new(
      source_token: env["HOOKLINE_STRIPE_SOURCE_TOKEN"],
      stripe_secret: env["HOOKLINE_STRIPE_SIGNING_SECRET"],
      target_url: env["HOOKLINE_LEDGERLINE_URL"],
      target_secret: env["HOOKLINE_LEDGERLINE_SECRET"]
    )
  end

  def initialize(source_token:, stripe_secret:, target_url:, target_secret:)
    @source_token = source_token
    @stripe_secret = stripe_secret
    @target_url = target_url
    @target_secret = target_secret
  end

  def configured?
    [ @source_token, @stripe_secret, @target_url, @target_secret ].all?(&:present?)
  end

  def call
    return false unless configured?
    raise ArgumentError, "source token must be 24 to 128 URL-safe characters" unless @source_token.match?(TOKEN_FORMAT)

    Source.transaction do
      source = Source.find_by_token(@source_token) ||
               Source.create!(name: SOURCE_NAME, token: @source_token, signing_secret: @stripe_secret, verification: "stripe")
      source.subscriptions.find_by(url: @target_url) ||
        source.subscriptions.create!(url: @target_url, signing_secret: @target_secret)
    end
    true
  end
end
