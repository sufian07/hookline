require "rails_helper"

RSpec.describe Subscription, "in demo mode", :demo_mode do
  let(:source) { create_source }

  it "only accepts the built-in demo receiver" do
    expect(source.subscriptions.new(url: "https://hookline-demo.example.com/demo/receiver")).to be_valid
    expect(source.subscriptions.new(url: "https://hookline-demo.example.com/demo/receiver?team=a")).to be_valid

    subscription = source.subscriptions.new(url: "https://receiver.example.com/hooks")
    expect(subscription).to be_invalid
    expect(subscription.errors[:url]).to include("must be the demo receiver in demo mode")
  end

  it "rejects look-alike hosts and paths" do
    [ "https://hookline-demo.example.com.evil.test/demo/receiver",
      "https://hookline-demo.example.com/demo/receiver-extra",
      "https://hookline-demo.example.com/api/sources" ].each do |url|
      expect(source.subscriptions.new(url:)).to be_invalid, url
    end
  end
end
