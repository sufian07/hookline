# Keeps the public demo alive: a new event every few minutes, delivered by the real worker.
class DemoTrafficJob < ApplicationJob
  def perform
    return unless Rails.configuration.x.demo_mode

    source = Source.find_by(name: DemoSeeder::SOURCE_NAME)
    return unless source

    random = Random.new
    event_type = DemoSeeder::EVENT_TYPES.sample(random:)
    EventReceiver.new(source).call(
      event_type:,
      idempotency_key: "live-#{SecureRandom.uuid}",
      payload: DemoSeeder.payload(SecureRandom.hex(4), event_type, random).to_json
    )
  end
end
