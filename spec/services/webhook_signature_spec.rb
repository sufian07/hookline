require "rails_helper"

RSpec.describe WebhookSignature do
  let(:now) { Time.utc(2026, 1, 1, 12) }
  let(:body) { '{"id":1}' }

  def verify(secret: "s3cret", timestamp: now.to_i.to_s, signed_body: body, received: body)
    signature = described_class.sign(secret: "s3cret", timestamp:, body: signed_body)
    described_class.valid?(secret:, timestamp:, body: received, signature:, now:)
  end

  it "matches an independently computed HMAC" do
    expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "k", "1700000000.hi")

    expect(described_class.sign(secret: "k", timestamp: "1700000000", body: "hi")).to eq(expected)
  end

  it "accepts a correctly signed body" do
    expect(verify).to be(true)
  end

  it "rejects a changed body" do
    expect(verify(received: '{"id":2}')).to be(false)
  end

  it "rejects the wrong secret" do
    expect(verify(secret: "other")).to be(false)
  end

  it "accepts the edge of the replay window and rejects beyond it, in both directions" do
    [ -300, 300 ].each { |s| expect(verify(timestamp: (now.to_i + s).to_s)).to be(true) }
    [ -301, 301 ].each { |s| expect(verify(timestamp: (now.to_i + s).to_s)).to be(false) }
  end

  it "rejects a missing signature or a malformed timestamp" do
    expect(described_class.valid?(secret: "k", timestamp: "1", body:, signature: nil, now:)).to be(false)
    expect(verify(timestamp: "12abc")).to be(false)
  end
end
