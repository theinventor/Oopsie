class Project < ApplicationRecord
  has_many :error_groups, dependent: :destroy
  has_many :notification_rules, dependent: :destroy

  validates :name, presence: true
  validates :api_key, presence: true, uniqueness: true

  before_validation :generate_api_key, on: :create

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end
