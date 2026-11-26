require "rails_helper"

RSpec.describe WebhookSignature, ".valid_stripe?" do
  let(:now) { Time.utc(2027, 1, 1) }
  let(:body) { '{"id":"evt_1","type":"checkout.session.completed"}' }

  def stripe_header(secret: "whsec_x", at: now.to_i, signed_body: body)
    "t=#{at},v1=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{at}.#{signed_body}")}"
  end

  def check(header)
    described_class.valid_stripe?(secret: "whsec_x", header:, body:, now:)
  end

  it "accepts a valid Stripe signature" do
    expect(check(stripe_header)).to be(true)
  end

  it "accepts any matching v1 among several" do
    expect(check("t=#{now.to_i},v1=#{'0' * 64},#{stripe_header.split(',').last}")).to be(true)
  end

  it "rejects a wrong secret, a changed body, and an old timestamp" do
    expect(check(stripe_header(secret: "other"))).to be(false)
    expect(check(stripe_header(signed_body: "{}"))).to be(false)
    expect(check(stripe_header(at: now.to_i - 301))).to be(false)
  end

  it "rejects malformed headers" do
    [ "", "t=abc,v1=00", "v1=#{'0' * 64}", "t=#{now.to_i}", nil ].each { |header| expect(check(header)).to be(false) }
  end
end
