module ApplicationHelper
  def status_badge_class(status)
    case status.to_s
    when "unresolved" then "danger"
    when "resolved" then "success"
    when "ignored" then "muted"
    else "muted"
    end
  end
end
