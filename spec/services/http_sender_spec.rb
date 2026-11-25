require "rails_helper"

RSpec.describe HttpSender do
  let(:url) { "https://receiver.example.com/hooks?a=1" }
  let(:guard) { DestinationGuard.new(resolver: ->(_host) { [ "93.184.216.34" ] }) }

  def post
    described_class.new(guard:).post(url, body: "{}", headers: { "X-Test" => "1" })
  end

  it "posts the body and headers and reports the status code" do
    request = stub_request(:post, url).with(body: "{}", headers: { "X-Test" => "1" }).to_return(status: 204)

    expect(post).to have_attributes(code: 204, error: nil, success?: true)
    expect(request).to have_been_requested.once
  end

  it "connects to the address that was checked" do
    stub_request(:post, url)
    expect_any_instance_of(Net::HTTP).to receive(:ipaddr=).with("93.184.216.34").and_call_original

    post
  end

  it "treats 4xx and 5xx as failures" do
    [ 404, 503 ].each do |status|
      stub_request(:post, url).to_return(status:)

      expect(post).to have_attributes(code: status, success?: false)
    end
  end

  it "does not follow redirects" do
    stub_request(:post, url).to_return(status: 302, headers: { "Location" => "https://127.0.0.1/" })

    expect(post).to have_attributes(code: 302, success?: false)
    expect(a_request(:any, "https://127.0.0.1/")).not_to have_been_made
  end

  it "reports timeouts and connection errors instead of raising" do
    [ Net::OpenTimeout, Errno::ECONNREFUSED, SocketError, OpenSSL::SSL::SSLError ].each do |error|
      stub_request(:post, url).to_raise(error)

      expect(post).to have_attributes(code: nil, error: error.name, success?: false)
    end
  end

  it "makes no request to a blocked destination" do
    blocking = DestinationGuard.new(resolver: ->(_host) { [ "127.0.0.1" ] })
    result = described_class.new(guard: blocking).post(url, body: "{}", headers: {})

    expect(result).to have_attributes(code: nil, error: "DestinationGuard::Blocked", success?: false)
    expect(a_request(:post, url)).not_to have_been_made
  end
end
