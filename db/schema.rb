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

ActiveRecord::Schema[8.1].define(version: 2026_02_13_155459) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "documentation_tasks", force: :cascade do |t|
    t.text "class_context"
    t.datetime "created_at", null: false
    t.string "method_signature", null: false
    t.integer "pr_status"
    t.string "pr_url"
    t.bigint "project_id", null: false
    t.text "reviewer_note"
    t.text "source_code", null: false
    t.string "source_file_path", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["pr_status"], name: "index_documentation_tasks_on_pr_status"
    t.index ["project_id", "method_signature"], name: "index_documentation_tasks_on_project_id_and_method_signature", unique: true
    t.index ["project_id"], name: "index_documentation_tasks_on_project_id"
    t.index ["status"], name: "index_documentation_tasks_on_status"
  end

  create_table "draft_versions", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "documentation_task_id", null: false
    t.integer "label", null: false
    t.text "prompt_used"
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0, null: false
    t.boolean "winner", default: false, null: false
    t.index ["documentation_task_id", "label"], name: "index_draft_versions_on_documentation_task_id_and_label", unique: true
    t.index ["documentation_task_id"], name: "index_draft_versions_on_documentation_task_id"
    t.index ["documentation_task_id"], name: "index_draft_versions_on_task_id_winner", unique: true, where: "(winner = true)"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_branch", default: "main", null: false
    t.string "github_repo", null: false
    t.datetime "last_scanned_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["github_repo"], name: "index_projects_on_github_repo", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.boolean "digest_opted_in", default: true, null: false
    t.string "email"
    t.string "github_uid", null: false
    t.string "github_username", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["github_uid"], name: "index_users_on_github_uid", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "documentation_task_id", null: false
    t.bigint "draft_version_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["documentation_task_id"], name: "index_votes_on_documentation_task_id"
    t.index ["draft_version_id"], name: "index_votes_on_draft_version_id"
    t.index ["user_id", "documentation_task_id"], name: "index_votes_on_user_id_and_documentation_task_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "documentation_tasks", "projects"
  add_foreign_key "draft_versions", "documentation_tasks"
  add_foreign_key "votes", "documentation_tasks"
  add_foreign_key "votes", "draft_versions"
  add_foreign_key "votes", "users"
end
