require "test_helper"

class NotificationRuleTest < ActiveSupport::TestCase
  test "valid email rule" do
    rule = NotificationRule.new(
      project: projects(:myapp),
      channel: :email,
      destination: "dev@example.com"
    )
    assert rule.valid?
    assert rule.enabled?, "should default to enabled"
  end

  test "valid webhook rule" do
    rule = NotificationRule.new(
      project: projects(:myapp),
      channel: :webhook,
      destination: "https://hooks.example.com/notify"
    )
    assert rule.valid?
  end

  test "requires channel and destination" do
    rule = NotificationRule.new(project: projects(:myapp))
    assert_not rule.valid?
    assert_includes rule.errors[:channel], "can't be blank"
    assert_includes rule.errors[:destination], "can't be blank"
  end
end
