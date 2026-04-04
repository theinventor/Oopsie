require "test_helper"

class OccurrenceTest < ActiveSupport::TestCase
  test "valid occurrence" do
    occurrence = Occurrence.new(
      error_group: error_groups(:nomethoderror),
      message: "test error",
      occurred_at: Time.current
    )
    assert occurrence.valid?
  end

  test "requires occurred_at" do
    occurrence = Occurrence.new(
      error_group: error_groups(:nomethoderror),
      message: "test error"
    )
    assert_not occurrence.valid?
    assert_includes occurrence.errors[:occurred_at], "can't be blank"
  end

  test "counter cache increments on create" do
    group = error_groups(:nomethoderror)
    original_count = group.occurrences_count

    Occurrence.create!(
      error_group: group,
      message: "new occurrence",
      occurred_at: Time.current
    )

    assert_equal original_count + 1, group.reload.occurrences_count
  end
end
