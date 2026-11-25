require "rails_helper"

RSpec.describe Backoff do
  it "doubles from 30 seconds when jitter is at its maximum" do
    delays = (1..4).map { |n| described_class.delay(n, jitter: 1.0) }

    expect(delays).to eq([ 30, 60, 120, 240 ])
  end

  it "never waits less than half the step, so retries cannot bunch at zero" do
    expect(described_class.delay(2, jitter: 0.0)).to eq(30)
  end

  it "is capped at one hour" do
    expect(described_class.delay(50, jitter: 1.0)).to eq(3600)
  end
end
