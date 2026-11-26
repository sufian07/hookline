# Measures ingest throughput and latency against a running Hookline.
#
#   ruby script/load_test.rb BASE_URL ADMIN_TOKEN [REQUESTS] [CONCURRENCY]
#
# Creates its own source, then sends signed events from several threads, each
# on one keep-alive connection. Uses only the standard library.
require "json"
require "net/http"
require "openssl"
require "securerandom"

base = URI(ARGV.fetch(0))
admin_token = ARGV.fetch(1)
total = Integer(ARGV.fetch(2, 2000))
concurrency = Integer(ARGV.fetch(3, 8))

secret = SecureRandom.hex(16)
created = Net::HTTP.start(base.host, base.port, use_ssl: base.scheme == "https") do |http|
  request = Net::HTTP::Post.new("/api/sources", "Authorization" => "Bearer #{admin_token}",
                                                "Content-Type" => "application/json")
  request.body = { name: "Load test #{Time.now.to_i}", signing_secret: secret }.to_json
  http.request(request)
end
abort "Could not create a source: #{created.code} #{created.body}" unless created.code == "201"
path = "/in/#{JSON.parse(created.body).fetch("token")}"

queue = Queue.new
total.times { |n| queue << n }
queue.close
latencies = Queue.new
statuses = Queue.new

started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
threads = Array.new(concurrency) do
  Thread.new do
    Net::HTTP.start(base.host, base.port, use_ssl: base.scheme == "https") do |http|
      while (n = queue.pop)
        body = { n:, at: Time.now.to_f }.to_json
        timestamp = Time.now.to_i.to_s
        signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
        request = Net::HTTP::Post.new(path, "Content-Type" => "application/json",
                                            "X-Hookline-Timestamp" => timestamp,
                                            "X-Hookline-Signature" => signature,
                                            "X-Hookline-Event" => "load.test",
                                            "X-Hookline-Idempotency-Key" => "load-#{n}-#{SecureRandom.hex(4)}")
        request.body = body
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        response = http.request(request)
        latencies << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000
        statuses << response.code
      end
    end
  end
end
threads.each(&:join)
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

times = Array.new(latencies.size) { latencies.pop }.sort
codes = Array.new(statuses.size) { statuses.pop }.tally
percentile = ->(p) { times[[ (p / 100.0 * times.size).ceil - 1, 0 ].max].round(1) }

puts "| Measure | Value |"
puts "|---|---|"
puts "| Requests | #{total} signed ingest requests, #{concurrency} concurrent connections |"
puts "| Duration | #{elapsed.round(2)} s |"
puts "| Throughput | #{(total / elapsed).round} requests/s |"
puts "| Latency p50 / p95 / p99 | #{percentile.(50)} / #{percentile.(95)} / #{percentile.(99)} ms |"
puts "| Responses | #{codes.sort.map { |code, count| "#{code}: #{count}" }.join(", ")} |"
exit(codes.keys == [ "202" ] ? 0 : 1)
