class ErrorGroup < ApplicationRecord
  belongs_to :project
  has_many :occurrences, dependent: :destroy

  enum :status, { unresolved: 0, resolved: 1, ignored: 2 }

  validates :fingerprint, presence: true, uniqueness: { scope: :project_id }
  validates :error_class, presence: true
  validates :first_seen_at, presence: true
  validates :last_seen_at, presence: true

  scope :by_last_seen, -> { order(last_seen_at: :desc) }

  def self.generate_fingerprint(error_class:, first_line:, message: nil)
    if first_line.present? && first_line["file"].present? && first_line["method"].present?
      Digest::SHA256.hexdigest("#{error_class}:#{first_line['file']}:#{first_line['method']}")
    else
      normalized = normalize_message(message || "")
      Digest::SHA256.hexdigest("#{error_class}:#{normalized}")
    end
  end

  def self.normalize_message(message)
    message
      .gsub(/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i, "<UUID>")
      .gsub(/0x[a-f0-9]+/i, "<HEX>")
      .gsub(/"[^"]*"/, "<STR>")
      .gsub(/'[^']*'/, "<STR>")
      .gsub(/\d+/, "<N>")
  end
end
