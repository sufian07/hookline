# The built-in endpoint that demo subscriptions deliver to.
module DemoReceiver
  PATH = "/demo/receiver".freeze
  FAILURE_RATE = 1 / 3.0

  module_function

  def url
    base = Rails.configuration.x.app_url
    base.present? ? URI.join(base, PATH).to_s : nil
  end

  def status_for(roll)
    roll < FAILURE_RATE ? 503 : 200
  end

  def url?(candidate)
    target = URI.parse(candidate.to_s)
    base = URI.parse(Rails.configuration.x.app_url.to_s)
    base.host.present? && target.is_a?(URI::HTTPS) &&
      target.host == base.host && target.port == base.port && target.path == PATH
  rescue URI::InvalidURIError
    false
  end
end
