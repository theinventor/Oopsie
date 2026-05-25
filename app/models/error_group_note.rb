class ErrorGroupNote < ApplicationRecord
  belongs_to :error_group

  enum :kind, {
    note: 0,
    workflow_state_change: 1,
    status_change: 2
  }

  validates :kind, presence: true
  validates :body, presence: true, if: :note?
  validates :actor_kind, presence: true
  validates :actor_label, presence: true
  validates :source, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
