class ErrorGroup < ApplicationRecord
  belongs_to :project
  has_many :occurrences, dependent: :destroy
  has_many :error_group_notes, dependent: :destroy

  enum :status, { unresolved: 0, resolved: 1, ignored: 2 }
  enum :workflow_state, {
    untriaged: 0,
    looking: 1,
    in_progress: 2,
    blocked: 3,
    ready_to_resolve: 4
  }

  validates :fingerprint, presence: true, uniqueness: { scope: :project_id }
  validates :error_class, presence: true
  validates :first_seen_at, presence: true
  validates :last_seen_at, presence: true
  validates :workflow_state_changed_at, presence: true

  scope :by_last_seen, -> { order(last_seen_at: :desc) }
  scope :with_workflow_state, ->(state) { where(workflow_state: normalize_workflow_state!(state)) }

  before_validation :set_default_workflow_state_changed_at
  before_save :set_workflow_state_changed_at, if: :will_save_change_to_workflow_state?

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

  def self.normalize_workflow_state!(state)
    normalized = state.to_s.strip
    return normalized if workflow_states.key?(normalized)

    raise ArgumentError, "Invalid workflow state '#{state}'. Use one of: #{workflow_states.keys.join(', ')}."
  end

  def self.normalize_status!(target_status)
    normalized = target_status.to_s.strip
    return normalized if statuses.key?(normalized)

    raise ArgumentError, "Invalid status '#{target_status}'. Use one of: #{statuses.keys.join(', ')}."
  end

  def set_workflow_state!(state, actor:, source:, note: nil)
    normalized = self.class.normalize_workflow_state!(state)
    previous = workflow_state
    changed = previous != normalized

    transaction do
      update!(workflow_state: normalized, workflow_state_changed_at: Time.current) if changed || workflow_state_changed_at.blank?

      if changed || note.present?
        error_group_notes.create!(
          audit_attributes(actor: actor, source: source).merge(
            kind: :workflow_state_change,
            body: note.presence,
            from_value: previous,
            to_value: normalized
          )
        )
      end
    end

    self
  end

  def add_note!(body, actor:, source:)
    error_group_notes.create!(
      audit_attributes(actor: actor, source: source).merge(
        kind: :note,
        body: body
      )
    )
  end

  def transition_status!(target_status, actor:, source:, note: nil)
    normalized = self.class.normalize_status!(target_status)
    previous = status
    changed = previous != normalized

    transaction do
      update!(status: normalized) if changed

      if changed
        error_group_notes.create!(
          audit_attributes(actor: actor, source: source).merge(
            kind: :status_change,
            body: note.presence,
            from_value: previous,
            to_value: normalized
          )
        )
      elsif note.present?
        add_note!(note, actor: actor, source: source)
      end
    end

    self
  end

  private

  def set_default_workflow_state_changed_at
    self.workflow_state_changed_at ||= first_seen_at || Time.current
  end

  def set_workflow_state_changed_at
    self.workflow_state_changed_at = Time.current unless new_record?
  end

  def audit_attributes(actor:, source:)
    actor_label =
      case actor
      when User then actor.email_address
      when Project then actor.name
      when Hash then actor[:label] || actor["label"]
      else actor.to_s
      end

    actor_kind =
      case actor
      when User then "user"
      when Project then "project"
      when Hash then actor[:kind] || actor["kind"]
      else "system"
      end

    {
      actor_kind: actor_kind.presence || "system",
      actor_label: actor_label.presence || "system",
      source: source.to_s.presence || "unknown"
    }
  end
end
