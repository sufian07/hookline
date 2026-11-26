require "rails_helper"

RSpec.describe DemoSeeder, :demo_mode do
  let(:now) { Time.utc(2026, 11, 26, 12) }

  def seed
    described_class.new(random: Random.new(7), now:).call
  end

  it "creates a demo source whose subscriptions all point at the demo receiver" do
    expect(seed).to be(true)

    source = Source.sole
    expect(source.name).to eq(DemoSeeder::SOURCE_NAME)
    expect(source.subscriptions.map(&:url)).to all(start_with(DemoReceiver.url))
    expect(source.subscriptions.pluck(:event_filter)).to contain_exactly(nil, "order.refunded")
  end

  it "builds a history with delivered, retrying and dead deliveries" do
    seed

    expect(Event.count).to eq(DemoSeeder::EVENT_COUNT)
    expect(Delivery.distinct.pluck(:status)).to contain_exactly("delivered", "pending", "dead")
    expect(Event.maximum(:received_at)).to be <= now
  end

  it "keeps attempt records consistent with each delivery" do
    seed

    Delivery.includes(:delivery_attempts).find_each do |delivery|
      attempts = delivery.delivery_attempts.sort_by(&:number)
      expect(attempts.map(&:number)).to eq((1..delivery.attempts_count).to_a)
      expect(attempts.last.response_code).to eq(200) if delivery.status == "delivered"
      expect(attempts.size).to eq(delivery.attempt_limit) if delivery.status == "dead"
      expect(attempts.map(&:response_code)).not_to include(200) unless delivery.status == "delivered"
    end
  end

  it "schedules retrying deliveries in the future and enqueues nothing itself" do
    expect { seed }.not_to have_enqueued_job

    expect(Delivery.where(status: "pending").pluck(:next_attempt_at)).to all(be > now)
  end

  it "does nothing when the database already has data" do
    create_source

    expect(seed).to be(false)
    expect(Source.count).to eq(1)
  end

  it "needs the public URL to build receiver addresses" do
    Rails.configuration.x.app_url = nil

    expect { seed }.to raise_error(ArgumentError, /APP_URL/)
  end
end
