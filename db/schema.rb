# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_04_033126) do
  create_table "error_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error_class", null: false
    t.string "fingerprint", null: false
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.string "message"
    t.integer "occurrences_count", default: 0, null: false
    t.integer "project_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "fingerprint"], name: "index_error_groups_on_project_id_and_fingerprint", unique: true
    t.index ["project_id", "status", "last_seen_at"], name: "index_error_groups_on_project_id_and_status_and_last_seen_at"
    t.index ["project_id"], name: "index_error_groups_on_project_id"
  end

  create_table "notification_rules", force: :cascade do |t|
    t.integer "channel", null: false
    t.datetime "created_at", null: false
    t.string "destination", null: false
    t.boolean "enabled", default: true, null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_notification_rules_on_project_id"
  end

  create_table "occurrences", force: :cascade do |t|
    t.json "backtrace"
    t.json "causes"
    t.json "context"
    t.datetime "created_at", null: false
    t.string "environment"
    t.integer "error_group_id", null: false
    t.json "first_line"
    t.boolean "handled", default: false, null: false
    t.string "message"
    t.string "notifier_version"
    t.datetime "occurred_at", null: false
    t.json "server_info"
    t.datetime "updated_at", null: false
    t.index ["error_group_id", "occurred_at"], name: "index_occurrences_on_error_group_id_and_occurred_at"
    t.index ["error_group_id"], name: "index_occurrences_on_error_group_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_projects_on_api_key", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "error_groups", "projects"
  add_foreign_key "notification_rules", "projects"
  add_foreign_key "occurrences", "error_groups"
  add_foreign_key "sessions", "users"
end
