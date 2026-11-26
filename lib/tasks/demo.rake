namespace :hookline do
  desc "Load demo data into an empty database (demo mode only)"
  task demo_seed: :environment do
    abort "HOOKLINE_DEMO_MODE is not enabled" unless Rails.configuration.x.demo_mode

    puts DemoSeeder.new.call ? "Demo data loaded." : "Database already has data; demo data skipped."
  end

  desc "Create the Stripe-to-Ledgerline pipeline from HOOKLINE_STRIPE_* and HOOKLINE_LEDGERLINE_* settings"
  task payment_pipeline: :environment do
    puts PaymentPipeline.from_env.call ? "Payment pipeline ready." : "Payment pipeline not configured; skipped."
  end
end
