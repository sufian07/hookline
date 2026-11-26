require "resolv"

# Decides whether a URL may be called, and returns the checked address. Callers must
# connect to that address: resolving again would allow DNS rebinding.
class DestinationGuard
  Blocked = Class.new(StandardError)

  BLOCKED_IPV4 = %w[
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
    192.0.0.0/24 192.0.2.0/24 192.88.99.0/24 192.168.0.0/16 198.18.0.0/15
    198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4
  ].map { |range| IPAddr.new(range) }.freeze

  # Only global unicast IPv6 is allowed, minus ranges that embed or tunnel other addresses.
  GLOBAL_IPV6 = IPAddr.new("2000::/3")
  BLOCKED_IPV6 = %w[ 2001::/23 2001:db8::/32 2002::/16 3fff::/20 ].map { |range| IPAddr.new(range) }.freeze

  def initialize(resolver: ->(host) { Resolv.getaddresses(host) })
    @resolver = resolver
  end

  # Shape-only check, without DNS: used when a subscription is saved.
  def self.check_format(url)
    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTPS) && uri.hostname.present? && uri.userinfo.nil?
      raise Blocked, "must be https without credentials"
    end
    uri
  rescue URI::InvalidURIError
    raise Blocked, "is malformed"
  end

  def resolve(url)
    addresses = @resolver.call(self.class.check_format(url).hostname)
    raise Blocked, "host does not resolve" if addresses.empty?
    raise Blocked, "address not allowed" unless addresses.all? { |address| public?(address) }

    addresses.first
  end

  private


  def public?(address)
    ip = IPAddr.new(address)
    if ip.ipv4?
      BLOCKED_IPV4.none? { |range| range.include?(ip) }
    else
      GLOBAL_IPV6.include?(ip) && BLOCKED_IPV6.none? { |range| range.include?(ip) }
    end
  rescue IPAddr::Error
    false
  end
end
