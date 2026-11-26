require "rails_helper"

RSpec.describe DemoReceiver do
  it "fails about a third of the time" do
    expect(described_class.status_for(0.0)).to eq(503)
    expect(described_class.status_for(0.33)).to eq(503)
    expect(described_class.status_for(0.34)).to eq(200)
    expect(described_class.status_for(0.99)).to eq(200)
  end

  it "builds its URL from the public base URL", :demo_mode do
    expect(described_class.url).to eq("https://hookline-demo.example.com/demo/receiver")
  end
end
