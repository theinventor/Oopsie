class NotificationRule < ApplicationRecord
  belongs_to :project

  enum :channel, { email: 0, webhook: 1 }

  validates :channel, presence: true
  validates :destination, presence: true
  validate :destination_is_valid_url, if: -> { webhook? && destination.present? }

  private

  def destination_is_valid_url
    uri = URI.parse(destination)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:destination, "must be an HTTP or HTTPS URL")
    end
  rescue URI::InvalidURIError
    errors.add(:destination, "is not a valid URL")
  end
end
