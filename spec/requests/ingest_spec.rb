require "rails_helper"

RSpec.describe "POST /in/:token" do
  let(:source) { create_source }
  let(:body) { '{"order":42}' }

  def ingest(raw = body, token: source.token, headers: signed_headers(raw))
    post "/in/#{token}", params: raw, headers:
  end

  it "stores the event and answers 202" do
    expect { ingest }.to change(Event, :count).by(1)

    expect(response).to have_http_status(:accepted)
    expect(Event.last).to have_attributes(event_type: "order.paid", idempotency_key: "evt-1", payload: body)
  end

  it "keeps the raw body byte for byte, so signatures stay meaningful" do
    ingest('{"b":1,  "a":2}')

    expect(Event.last.payload).to eq('{"b":1,  "a":2}')
  end

  it "answers 404 for an unknown token" do
    ingest(token: "nope")

    expect(response).to have_http_status(:not_found)
  end

  it "rejects a bad signature without storing anything" do
    expect { ingest(headers: signed_headers(body, secret: "wrong")) }.not_to change(Event, :count)

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a stale request" do
    ingest(headers: signed_headers(body, at: 6.minutes.ago))

    expect(response).to have_http_status(:unauthorized)
  end

  it "treats a repeated key with the same body as a duplicate" do
    ingest
    expect { ingest }.not_to change(Event, :count)

    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body).to include("duplicate" => true)
  end

  it "refuses a repeated key with a different body" do
    ingest
    ingest('{"order":43}')

    expect(response).to have_http_status(:conflict)
  end

  it "scopes idempotency keys to the source" do
    other = create_source(name: "Other")
    ingest

    expect { ingest(token: other.token) }.to change(Event, :count).by(1)
  end

  it "requires an event type and an idempotency key" do
    ingest(headers: signed_headers(body).except("X-Hookline-Event"))
    expect(response).to have_http_status(:unprocessable_content)

    ingest(headers: signed_headers(body).except("X-Hookline-Idempotency-Key"))
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects a body that is not JSON" do
    ingest("not json")

    expect(response).to have_http_status(:unprocessable_content)
    expect(Event.count).to eq(0)
  end

  it "rejects a body over the size limit" do
    ingest({ data: "x" * IngestController::MAX_BODY_BYTES }.to_json)

    expect(response).to have_http_status(:content_too_large)
  end
end
