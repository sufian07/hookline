require "rails_helper"

RSpec.describe Source, "with a chosen token" do
  it "keeps a token given at creation, stored only as a digest" do
    source = Source.create!(name: "Fixed", signing_secret: "s", token: "chosen_token_0123456789abcdef")

    expect(Source.find_by_token("chosen_token_0123456789abcdef")).to eq(source)
    expect(source.token_digest).not_to include("chosen")
  end
end
