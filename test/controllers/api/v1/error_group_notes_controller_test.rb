require "test_helper"

class Api::V1::ErrorGroupNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:myapp)
    @headers = { "Authorization" => "Bearer #{@project.api_key}", "Content-Type" => "application/json" }
    @error_group = error_groups(:nomethoderror)
  end

  test "creates a note for an error group" do
    assert_difference "ErrorGroupNote.note.count", 1 do
      post api_v1_error_group_notes_url(@error_group),
        params: { body: "Confirmed the failing account id." }.to_json,
        headers: @headers.merge("X-Oopsie-Client" => "cli/oopsie test")
    end

    assert_response :created
    note = @error_group.error_group_notes.note.last
    json = JSON.parse(response.body)

    assert_equal "Confirmed the failing account id.", note.body
    assert_equal "cli/oopsie test", note.source
    assert_equal note.id, json["note"]["id"]
    assert_equal "untriaged", json["error_group"]["workflow_state"]
  end

  test "rejects blank note body" do
    assert_no_difference "ErrorGroupNote.count" do
      post api_v1_error_group_notes_url(@error_group),
        params: { body: "" }.to_json,
        headers: @headers
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["details"], "Body can't be blank"
  end

  test "cannot create note on another project group" do
    other_project = projects(:otherapp)
    other_headers = { "Authorization" => "Bearer #{other_project.api_key}", "Content-Type" => "application/json" }

    assert_no_difference "ErrorGroupNote.count" do
      post api_v1_error_group_notes_url(@error_group),
        params: { body: "Should not attach." }.to_json,
        headers: other_headers
    end

    assert_response :not_found
  end

  test "supports user key with explicit project context" do
    headers = {
      "Authorization" => "Bearer #{users(:one).api_key}",
      "Content-Type" => "application/json",
      "X-Project-Id" => @project.id.to_s
    }

    post api_v1_error_group_notes_url(@error_group),
      params: { body: "Added from user key." }.to_json,
      headers: headers

    assert_response :created
    note = @error_group.error_group_notes.note.last
    assert_equal "user", note.actor_kind
    assert_equal users(:one).email_address, note.actor_label
  end
end
