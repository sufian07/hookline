require "rails_helper"

RSpec.describe "Dashboard entry point" do
  it "sends the root to the dashboard" do
    get "/"

    expect(response).to redirect_to("/dashboard/")
  end
end
