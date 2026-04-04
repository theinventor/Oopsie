class NotificationRule < ApplicationRecord
  belongs_to :project

  enum :channel, { email: 0, webhook: 1 }

  validates :channel, presence: true
  validates :destination, presence: true
end
