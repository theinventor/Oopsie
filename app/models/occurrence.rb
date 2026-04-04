class Occurrence < ApplicationRecord
  belongs_to :error_group, counter_cache: true

  validates :occurred_at, presence: true
end
