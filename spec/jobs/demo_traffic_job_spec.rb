require "rails_helper"

RSpec.describe DemoTrafficJob do
  it "sends one new event through the normal pipeline in demo mode", :demo_mode do
    DemoSeeder.new(random: Random.new(7)).call

    expect { described_class.perform_now }.to change(Event, :count).by(1).and have_enqueued_job(DeliverJob).at_least(:once)
    expect(Event.order(:id).last.idempotency_key).to start_with("live-")
  end

  it "does nothing outside demo mode" do
    expect { described_class.perform_now }.not_to change(Event, :count)
  end

  it "does nothing before the demo data exists", :demo_mode do
    expect { described_class.perform_now }.not_to change(Event, :count)
  end
end
