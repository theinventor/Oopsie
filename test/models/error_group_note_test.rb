require "test_helper"

class ErrorGroupNoteTest < ActiveSupport::TestCase
  test "note requires a body" do
    note = ErrorGroupNote.new(
      error_group: error_groups(:nomethoderror),
      kind: :note,
      actor_kind: "user",
      actor_label: "agent@example.com",
      source: "test"
    )

    assert_not note.valid?
    assert_includes note.errors[:body], "can't be blank"
  end

  test "history rows do not require a body" do
    note = ErrorGroupNote.new(
      error_group: error_groups(:nomethoderror),
      kind: :workflow_state_change,
      from_value: "untriaged",
      to_value: "looking",
      actor_kind: "user",
      actor_label: "agent@example.com",
      source: "test"
    )

    assert note.valid?
  end

  test "recent orders newest first" do
    group = error_groups(:nomethoderror)
    old_note = group.add_note!("older", actor: users(:one), source: "test")
    old_note.update!(created_at: 1.minute.ago)
    new_note = group.add_note!("newer", actor: users(:one), source: "test")
    new_note.update!(created_at: Time.current)

    assert_equal [ new_note, old_note ], group.error_group_notes.recent.limit(2).to_a
  end
end
