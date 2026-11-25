require "rails_helper"

RSpec.describe DestinationGuard do
  def resolve(url, *addresses)
    described_class.new(resolver: ->(_host) { addresses }).resolve(url)
  end

  it "returns the address to connect to for a public https URL" do
    expect(resolve("https://example.com/hook", "93.184.216.34")).to eq("93.184.216.34")
    expect(resolve("https://example.com/hook", "2606:4700::1111")).to eq("2606:4700::1111")
  end

  %w[
    127.0.0.1 10.0.0.5 172.16.0.1 192.168.1.1 169.254.169.254 100.64.0.1 0.0.0.0
    198.18.0.1 224.0.0.1 255.255.255.255
    ::1 :: fe80::1 fd00::1 ff02::1 ::ffff:127.0.0.1 64:ff9b::7f00:1 2002:7f00:1::
  ].each do |address|
    it "blocks #{address}" do
      expect { resolve("https://example.com", address) }.to raise_error(DestinationGuard::Blocked)
    end
  end

  it "blocks a host when any of its addresses is private" do
    expect { resolve("https://example.com", "93.184.216.34", "10.0.0.1") }.to raise_error(DestinationGuard::Blocked)
  end

  it "blocks a host that does not resolve" do
    expect { resolve("https://example.com") }.to raise_error(DestinationGuard::Blocked)
  end

  [ "http://example.com", "https://u:p@example.com", "ftp://example.com", "https://", "%%" ].each do |url|
    it "blocks the URL #{url}" do
      expect { resolve(url, "93.184.216.34") }.to raise_error(DestinationGuard::Blocked)
    end
  end
end
