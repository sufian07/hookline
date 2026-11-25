require "rails_helper"

RSpec.describe Source do
  it "can be found by its token, which is stored only as a digest" do
    source = create_source

    expect(described_class.find_by_token(source.token)).to eq(source)
    expect(source.attributes.values).not_to include(source.token)
    expect(described_class.find(source.id).token).to be_nil
  end

  it "finds nothing for an unknown or blank token" do
    expect(described_class.find_by_token("nope")).to be_nil
    expect(described_class.find_by_token(nil)).to be_nil
  end

  it "encrypts the signing secret at rest" do
    source = create_source

    expect(source.reload.signing_secret).to eq("s3cret")
    expect(source.ciphertext_for(:signing_secret)).not_to include("s3cret")
  end

  it "requires a name and a secret" do
    expect(described_class.new).to be_invalid
  end
end
