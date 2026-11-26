module DemoModeHelpers
  DEMO_URL = "https://hookline-demo.example.com".freeze

  def with_demo_mode(enabled: true, app_url: DEMO_URL)
    config = Rails.configuration.x
    config.demo_mode = enabled
    config.app_url = app_url
    yield
  ensure
    config.demo_mode = false
    config.app_url = nil
  end
end

RSpec.configure do |config|
  config.include DemoModeHelpers
  config.around(:each, :demo_mode) { |example| with_demo_mode { example.run } }
end
