require "net/http"

class HttpSender
  Result = Data.define(:code, :error) do
    def success? = code.present? && code.between?(200, 299)
  end

  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10
  TOTAL_TIMEOUT = 20

  EXPECTED_ERRORS = [
    DestinationGuard::Blocked, SystemCallError, SocketError, IOError, Timeout::Error,
    OpenSSL::SSL::SSLError, Net::ProtocolError, Net::HTTPBadResponse, Resolv::ResolvError
  ].freeze

  def initialize(guard: DestinationGuard.new)
    @guard = guard
  end

  def post(url, body:, headers:)
    Timeout.timeout(TOTAL_TIMEOUT) do
      address = @guard.resolve(url)
      Result.new(code: perform(URI.parse(url), address, body, headers), error: nil)
    end
  rescue *EXPECTED_ERRORS => error
    Result.new(code: nil, error: error.class.name)
  end

  private

  def perform(uri, address, body, headers)
    # The explicit nil ignores proxy environment variables, which would bypass the pinned address.
    http = Net::HTTP.new(uri.hostname, uri.port, nil)
    http.ipaddr = address
    http.use_ssl = true
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http.max_retries = 0

    request = Net::HTTP::Post.new(uri, headers)
    request.body = body
    status_of(http, request)
  end

  # Leaves the response body unread, so a receiver cannot make us buffer a huge one.
  def status_of(http, request)
    http.start do
      http.request(request) { |response| return response.code.to_i }
    end
  end
end
