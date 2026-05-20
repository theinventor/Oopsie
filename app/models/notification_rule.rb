class NotificationRule < ApplicationRecord
  SUPPORTED_EVENTS = %w[new_error regression].freeze
  EVENT_ALIASES = {
    "error.created" => "new_error",
    "error.reopened" => "regression",
    "error.regressed" => "regression"
  }.freeze

  belongs_to :project

  enum :channel, { email: 0, webhook: 1 }

  validates :channel, presence: true
  validates :destination, presence: true
  validate :destination_is_valid_url, if: -> { webhook? && destination.present? }
  validate :events_are_supported

  before_validation :normalize_events

  def self.canonical_event(event)
    value = event.to_s.strip
    EVENT_ALIASES.fetch(value, value)
  end

  def events
    Array(self[:events]).presence || SUPPORTED_EVENTS
  end

  def events=(values)
    normalized = Array(values).flat_map { |value| value.to_s.split(",") }
                              .map { |value| self.class.canonical_event(value) }
                              .reject(&:blank?)
                              .uniq
    self[:events] = normalized
  end

  def notify_for_event?(event)
    events.include?(self.class.canonical_event(event))
  end

  private

  def normalize_events
    self.events = events
  end

  def events_are_supported
    values = Array(self[:events])

    if values.empty?
      errors.add(:events, "must include at least one event")
      return
    end

    unsupported = values - SUPPORTED_EVENTS
    if unsupported.any?
      errors.add(:events, "include unsupported event(s): #{unsupported.join(', ')}")
    end
  end

  def destination_is_valid_url
    uri = URI.parse(destination)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:destination, "must be an HTTP or HTTPS URL")
    end
  rescue URI::InvalidURIError
    errors.add(:destination, "is not a valid URL")
  end
end
