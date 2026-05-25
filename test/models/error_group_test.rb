require "test_helper"

class ErrorGroupTest < ActiveSupport::TestCase
  test "valid error group" do
    group = ErrorGroup.new(
      project: projects(:myapp),
      fingerprint: "unique_fp",
      error_class: "RuntimeError",
      message: "something broke",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    assert group.valid?
    assert group.unresolved?, "default status should be unresolved"
    assert group.untriaged?, "default workflow state should be untriaged"
    assert group.workflow_state_changed_at.present?
  end

  test "requires fingerprint, error_class, timestamps" do
    group = ErrorGroup.new(project: projects(:myapp))
    assert_not group.valid?
    assert_includes group.errors[:fingerprint], "can't be blank"
    assert_includes group.errors[:error_class], "can't be blank"
    assert_includes group.errors[:first_seen_at], "can't be blank"
    assert_includes group.errors[:last_seen_at], "can't be blank"
  end

  test "fingerprint unique per project" do
    existing = error_groups(:nomethoderror)
    duplicate = ErrorGroup.new(
      project: existing.project,
      fingerprint: existing.fingerprint,
      error_class: "SomeError",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    assert_not duplicate.valid?
  end

  test "same fingerprint allowed on different projects" do
    group = ErrorGroup.new(
      project: projects(:otherapp),
      fingerprint: error_groups(:nomethoderror).fingerprint,
      error_class: "SomeError",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    assert group.valid?
  end

  test "status enum values" do
    group = error_groups(:nomethoderror)
    assert group.unresolved?

    group.resolved!
    assert group.resolved?

    group.ignored!
    assert group.ignored?
  end

  test "workflow state enum values" do
    group = error_groups(:nomethoderror)
    assert group.untriaged?

    group.looking!
    assert group.looking?

    group.in_progress!
    assert group.in_progress?

    group.blocked!
    assert group.blocked?

    group.ready_to_resolve!
    assert group.ready_to_resolve?
  end

  test "set_workflow_state records history without changing lifecycle status" do
    group = error_groups(:nomethoderror)

    assert_difference "ErrorGroupNote.count", 1 do
      group.set_workflow_state!(
        :in_progress,
        actor: users(:one),
        source: "test",
        note: "Investigating locally."
      )
    end

    group.reload
    note = group.error_group_notes.last

    assert_equal "unresolved", group.status
    assert_equal "in_progress", group.workflow_state
    assert_equal "workflow_state_change", note.kind
    assert_equal "untriaged", note.from_value
    assert_equal "in_progress", note.to_value
    assert_equal "Investigating locally.", note.body
    assert_equal users(:one).email_address, note.actor_label
  end

  test "add_note records plain investigation note" do
    group = error_groups(:nomethoderror)

    note = group.add_note!("Found failing request path.", actor: users(:one), source: "test")

    assert_equal "note", note.kind
    assert_equal "Found failing request path.", note.body
    assert_nil note.from_value
    assert_nil note.to_value
    assert_equal "test", note.source
  end

  test "transition_status records lifecycle history without changing workflow state" do
    group = error_groups(:nomethoderror)
    group.set_workflow_state!(:looking, actor: users(:one), source: "test")

    assert_difference "ErrorGroupNote.status_change.count", 1 do
      group.transition_status!(:resolved, actor: users(:one), source: "test", note: "Fixed in PR.")
    end

    group.reload
    note = group.error_group_notes.status_change.last

    assert_equal "resolved", group.status
    assert_equal "looking", group.workflow_state
    assert_equal "unresolved", note.from_value
    assert_equal "resolved", note.to_value
    assert_equal "Fixed in PR.", note.body
  end

  test "invalid workflow state is rejected" do
    assert_raises(ArgumentError) do
      error_groups(:nomethoderror).set_workflow_state!(:new, actor: users(:one), source: "test")
    end
  end

  test "generate_fingerprint with first_line" do
    fp = ErrorGroup.generate_fingerprint(
      error_class: "NoMethodError",
      first_line: { "file" => "app/models/user.rb", "method" => "load" }
    )
    expected = Digest::SHA256.hexdigest("NoMethodError:app/models/user.rb:load")
    assert_equal expected, fp
  end

  test "generate_fingerprint falls back to normalized message" do
    fp = ErrorGroup.generate_fingerprint(
      error_class: "NoMethodError",
      first_line: nil,
      message: "undefined method 'foo' for object 12345"
    )
    normalized = ErrorGroup.normalize_message("undefined method 'foo' for object 12345")
    expected = Digest::SHA256.hexdigest("NoMethodError:#{normalized}")
    assert_equal expected, fp
  end

  test "normalize_message strips dynamic values" do
    msg = "User 12345 not found at 0xDEADBEEF with id a1b2c3d4-e5f6-7890-abcd-ef1234567890 and name \"John\""
    normalized = ErrorGroup.normalize_message(msg)
    assert_no_match(/12345/, normalized)
    assert_no_match(/DEADBEEF/, normalized)
    assert_no_match(/a1b2c3d4/, normalized)
    assert_no_match(/John/, normalized)
  end

  test "by_last_seen scope orders descending" do
    groups = ErrorGroup.by_last_seen.to_a
    assert groups.first.last_seen_at >= groups.last.last_seen_at
  end
end
