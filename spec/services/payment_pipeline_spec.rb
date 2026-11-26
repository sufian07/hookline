require "rails_helper"

RSpec.describe PaymentPipeline do
  let(:settings) do
    {
      source_token: "stripe_source_token_0123456789abcdef",
      stripe_secret: "whsec_from_stripe",
      target_url: "https://ledgerline.example.com/webhooks/hookline",
      target_secret: "shared-with-ledgerline"
    }
  end

  def run(overrides = {})
    described_class.new(**settings, **overrides).call
  end

  it "does nothing unless every setting is present" do
    expect(run(target_secret: nil)).to be(false)
    expect(run(stripe_secret: "")).to be(false)
    expect(Source.count).to eq(0)
  end

  it "creates a Stripe-signed source at a fixed token, and a subscription to Ledgerline" do
    expect(run).to be(true)

    source = Source.find_by_token(settings[:source_token])
    expect(source).to have_attributes(name: "Stripe payments", verification: "stripe", signing_secret: "whsec_from_stripe")
    expect(source.subscriptions.sole).to have_attributes(
      url: settings[:target_url], signing_secret: "shared-with-ledgerline", active: true, event_filter: nil
    )
  end

  it "can run on every boot without creating duplicates" do
    2.times { run }

    expect(Source.count).to eq(1)
    expect(Subscription.count).to eq(1)
  end

  it "refuses a token that is short or not URL-safe" do
    expect { run(source_token: "short") }.to raise_error(ArgumentError, /source token/)
    expect { run(source_token: "has/slash/0123456789abcdefghij") }.to raise_error(ArgumentError, /source token/)
  end

  it "is allowed in demo mode, where other subscriptions must target the demo receiver", :demo_mode do
    Rails.configuration.x.payment_pipeline_url = settings[:target_url]

    expect(run).to be(true)
    expect(Subscription.sole.url).to eq(settings[:target_url])
  ensure
    Rails.configuration.x.payment_pipeline_url = nil
  end
end
