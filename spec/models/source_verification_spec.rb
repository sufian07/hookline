require "rails_helper"

RSpec.describe Source, "verification" do
  it "defaults to Hookline signatures" do
    expect(create_source.verification).to eq("hookline")
  end

  it "only allows known schemes" do
    expect(Source.new(name: "x", signing_secret: "y", verification: "stripe")).to be_valid
    expect(Source.new(name: "x", signing_secret: "y", verification: "github")).to be_invalid
  end
end
