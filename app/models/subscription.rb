class Subscription < ApplicationRecord
  belongs_to :source
  has_many :deliveries, dependent: :restrict_with_error

  encrypts :signing_secret

  validates :url, :signing_secret, presence: true
  validate :url_is_deliverable, if: :url?
  validate :demo_receiver_only, if: -> { url? && Rails.configuration.x.demo_mode }

  before_validation(on: :create) { self.signing_secret ||= SecureRandom.hex(32) }

  scope :for_event_type, ->(type) { where(active: true, event_filter: [ nil, type ]) }

  private

  def url_is_deliverable
    DestinationGuard.check_format(url)
  rescue DestinationGuard::Blocked => error
    errors.add(:url, error.message)
  end

  def demo_receiver_only
    errors.add(:url, "must be the demo receiver in demo mode") unless DemoReceiver.url?(url)
  end
end
