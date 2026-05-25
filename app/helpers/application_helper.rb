module ApplicationHelper
  def status_badge_class(status)
    case status.to_s
    when "unresolved" then "danger"
    when "resolved" then "success"
    when "ignored" then "muted"
    else "muted"
    end
  end

  def workflow_state_label(state)
    state.to_s.humanize
  end

  def workflow_state_badge_class(state)
    case state.to_s
    when "blocked" then "danger"
    when "ready_to_resolve" then "success"
    when "looking", "in_progress" then "info"
    else "muted"
    end
  end
end
