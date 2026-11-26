#!/usr/bin/env bash
# End-to-end check with the real server and Solid Queue worker:
# create a source and subscription over the API, send a signed webhook,
# then wait until the worker has recorded a delivery attempt.
set -euo pipefail

export RAILS_ENV=development
export HOOKLINE_ADMIN_TOKEN="smoke-$(openssl rand -hex 8)"
PORT="${PORT:-3100}"
BASE="http://127.0.0.1:${PORT}"
AUTH="Authorization: Bearer ${HOOKLINE_ADMIN_TOKEN}"
JSON="Content-Type: application/json"
LOG_DIR="${LOG_DIR:-tmp/smoke}"

mkdir -p "$LOG_DIR"
bin/rails db:prepare

bin/rails server -p "$PORT" -b 127.0.0.1 > "$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!
bin/jobs > "$LOG_DIR/jobs.log" 2>&1 &
JOBS_PID=$!

cleanup() {
  kill "$SERVER_PID" "$JOBS_PID" 2>/dev/null || true
  wait 2>/dev/null || true
}
fail() {
  echo "FAIL: $1"
  echo "--- server log"; tail -n 40 "$LOG_DIR/server.log" || true
  echo "--- jobs log"; tail -n 40 "$LOG_DIR/jobs.log" || true
  exit 1
}
trap cleanup EXIT

json_field() { ruby -rjson -e "puts JSON.parse(STDIN.read).dig(*ARGV.map { |k| k =~ /\A\d+\z/ ? k.to_i : k })" "$@"; }

for _ in $(seq 60); do curl -sf "$BASE/up" > /dev/null && break; sleep 1; done
curl -sf "$BASE/up" > /dev/null || fail "server did not start"

SECRET="$(openssl rand -hex 16)"
SOURCE="$(curl -sf -H "$AUTH" -H "$JSON" -d "{\"name\":\"Smoke\",\"signing_secret\":\"$SECRET\"}" "$BASE/api/sources")"
SOURCE_ID="$(echo "$SOURCE" | json_field id)"
TOKEN="$(echo "$SOURCE" | json_field token)"

curl -sf -H "$AUTH" -H "$JSON" -d '{"url":"https://example.com/"}' "$BASE/api/sources/$SOURCE_ID/subscriptions" > /dev/null

BODY='{"smoke":true}'
TIMESTAMP="$(date +%s)"
SIGNATURE="sha256=$(printf '%s.%s' "$TIMESTAMP" "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')"
INGEST="$(curl -sf -H "$JSON" \
  -H "X-Hookline-Timestamp: $TIMESTAMP" -H "X-Hookline-Signature: $SIGNATURE" \
  -H "X-Hookline-Event: smoke.test" -H "X-Hookline-Idempotency-Key: smoke-$TIMESTAMP" \
  -d "$BODY" "$BASE/in/$TOKEN")"
EVENT_ID="$(echo "$INGEST" | json_field id)"
echo "Event $EVENT_ID accepted"

for _ in $(seq 60); do
  EVENT="$(curl -sf -H "$AUTH" "$BASE/api/events/$EVENT_ID")"
  if [ "$(echo "$EVENT" | json_field deliveries 0 attempts_count)" -ge 1 ]; then
    echo "Worker recorded an attempt:"
    echo "$EVENT" | json_field deliveries 0 attempts 0
    exit 0
  fi
  sleep 1
done

fail "no delivery attempt within 60 seconds"
