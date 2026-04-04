require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid project" do
    project = Project.new(name: "TestApp")
    assert project.valid?
    assert project.api_key.present?, "should auto-generate api_key"
  end

  test "requires name" do
    project = Project.new(name: nil)
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "generates unique api_key on create" do
    p1 = Project.create!(name: "App1")
    p2 = Project.create!(name: "App2")
    assert_not_equal p1.api_key, p2.api_key
  end

  test "does not overwrite provided api_key" do
    project = Project.new(name: "TestApp", api_key: "custom_key")
    assert_equal "custom_key", project.api_key
  end

  test "api_key must be unique" do
    Project.create!(name: "App1", api_key: "same_key")
    duplicate = Project.new(name: "App2", api_key: "same_key")
    assert_not duplicate.valid?
  end

  test "destroying project destroys error_groups" do
    project = projects(:myapp)
    assert_difference "ErrorGroup.count", -project.error_groups.count do
      project.destroy
    end
  end
end
