class Source < ApplicationRecord
  has_many :events, dependent: :restrict_with_error
  has_many :subscriptions, dependent: :restrict_with_error

  encrypts :signing_secret

  VERIFICATIONS = %w[hookline stripe].freeze

  validates :name, :signing_secret, presence: true
  validates :verification, inclusion: { in: VERIFICATIONS }

  before_validation :generate_token, on: :create

  # Plaintext token, available only on the instance that created it.
  attr_reader :token

  def self.find_by_token(token)
    token.present? ? find_by(token_digest: digest(token)) : nil
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  private

  def generate_token
    @token = SecureRandom.urlsafe_base64(24)
    self.token_digest = self.class.digest(@token)
  end
end
