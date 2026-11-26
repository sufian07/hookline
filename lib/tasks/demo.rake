namespace :hookline do
  desc "Load demo data into an empty database (demo mode only)"
  task demo_seed: :environment do
    abort "HOOKLINE_DEMO_MODE is not enabled" unless Rails.configuration.x.demo_mode

    puts DemoSeeder.new.call ? "Demo data loaded." : "Database already has data; demo data skipped."
  end
end
