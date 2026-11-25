class Subscription < ApplicationRecord
  belongs_to :source
  has_many :deliveries, dependent: :restrict_with_error

  encrypts :signing_secret

  validates :url, :signing_secret, presence: true

  before_validation(on: :create) { self.signing_secret ||= SecureRandom.hex(32) }

  scope :for_event_type, ->(type) { where(active: true, event_filter: [ nil, type ]) }
end
