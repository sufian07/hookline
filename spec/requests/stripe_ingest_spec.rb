require "rails_helper"

RSpec.describe "POST /in/:token for a Stripe-signed source" do
  let(:source) { create_source(verification: "stripe", signing_secret: "whsec_x") }
  let(:event) { { id: "evt_1", type: "checkout.session.completed", data: { object: { id: "cs_1" } } } }

  def stripe_post(payload, secret: "whsec_x", at: Time.current.to_i)
    body = payload.is_a?(String) ? payload : payload.to_json
    signature = "t=#{at},v1=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{at}.#{body}")}"
    post "/in/#{source.token}", params: body, headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => signature }
  end

  it "takes the event type and idempotency key from Stripe's event" do
    stripe_post(event)

    expect(response).to have_http_status(:accepted)
    expect(Event.sole).to have_attributes(event_type: "checkout.session.completed", idempotency_key: "evt_1")
  end

  it "stores Stripe's body unchanged, so it can be re-verified downstream" do
    raw = '{"id":"evt_1",  "type":"checkout.session.completed"}'
    stripe_post(raw)

    expect(Event.sole.payload).to eq(raw)
  end

  it "treats Stripe's redelivery of an event as a duplicate" do
    stripe_post(event)
    stripe_post(event)

    expect(response.parsed_body).to include("duplicate" => true)
    expect(Event.count).to eq(1)
  end

  it "rejects a bad Stripe signature" do
    stripe_post(event, secret: "whsec_wrong")

    expect(response).to have_http_status(:unauthorized)
  end

  it "does not accept Hookline signatures for a Stripe source" do
    post "/in/#{source.token}", params: event.to_json, headers: signed_headers(event.to_json, secret: "whsec_x")

    expect(response).to have_http_status(:unauthorized)
  end

  it "needs the event's id and type" do
    stripe_post({ data: {} })

    expect(response).to have_http_status(:unprocessable_content)
  end
end
