module ApiHelpers
  ADMIN_TOKEN = "test-admin-token".freeze

  def api_headers(token = ADMIN_TOKEN)
    { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
  end

  def json_body
    response.parsed_body
  end

  def receive_event(source, type: "order.paid", key: "evt-1", payload: '{"id":1}')
    EventReceiver.new(source).call(event_type: type, idempotency_key: key, payload:).event
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
  config.before(type: :request) { Rails.configuration.x.admin_token = ApiHelpers::ADMIN_TOKEN }
  config.before { RateLimits.store.clear }
end
