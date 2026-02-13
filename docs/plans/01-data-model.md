# Plan 01: Data Model & Migrations

## Goal
Create all core database tables, models, associations, validations, and enums as defined in the PRD.

## Prerequisites
- Plan 00 (Project Setup)

## Tasks

### 1. User Model
```
create_table :users do |t|
  t.string :github_uid, null: false, index: { unique: true }
  t.string :github_username, null: false
  t.string :avatar_url
  t.string :email
  t.decimal :vote_weight, precision: 5, scale: 2, default: 1.0, null: false
  t.integer :role, default: 0, null: false  # enum: voter=0, maintainer=1
  t.boolean :digest_opted_in, default: true, null: false
  t.timestamps
end
```
- Enum for `role`: `{ voter: 0, maintainer: 1 }`
- Validations: presence of `github_uid`, `github_username`; uniqueness of `github_uid`

### 2. Project Model
```
create_table :projects do |t|
  t.string :name, null: false
  t.string :github_repo, null: false, index: { unique: true }
  t.string :default_branch, default: "main", null: false
  t.datetime :last_scanned_at
  t.timestamps
end
```
- Seed the Rails project: `{ name: "Ruby on Rails", github_repo: "rails/rails", default_branch: "main" }`

### 3. DocumentationTask Model
```
create_table :documentation_tasks do |t|
  t.references :project, null: false, foreign_key: true
  t.integer :status, default: 0, null: false
  t.string :method_signature, null: false
  t.string :source_file_path, null: false
  t.text :source_code, null: false
  t.text :class_context
  t.references :winning_version, foreign_key: { to_table: :draft_versions }, null: true
  t.string :pr_url
  t.integer :pr_status  # enum: pending=0, open=1, merged=2, closed=3
  t.text :reviewer_note
  t.timestamps
end

add_index :documentation_tasks, [:project_id, :method_signature], unique: true
```
- Enum for `status`: `{ drafting: 0, voting: 1, pending_review: 2, approved: 3, submitted: 4, merged: 5, rejected: 6, closed: 7 }`
- Enum for `pr_status`: `{ pending: 0, open: 1, merged: 2, closed: 3 }`

### 4. DraftVersion Model
```
create_table :draft_versions do |t|
  t.references :documentation_task, null: false, foreign_key: true
  t.integer :label, null: false  # enum: a=0, b=1, c=2
  t.string :provider, null: false  # internal only: claude, openai, gemini
  t.text :content, null: false
  t.text :prompt_used
  t.integer :votes_count, default: 0, null: false  # counter cache
  t.timestamps
end

add_index :draft_versions, [:documentation_task_id, :label], unique: true
```
- Enum for `label`: `{ a: 0, b: 1, c: 2 }`

### 5. Vote Model
```
create_table :votes do |t|
  t.references :user, null: false, foreign_key: true
  t.references :documentation_task, null: false, foreign_key: true
  t.references :draft_version, null: false, foreign_key: true
  t.decimal :weight, precision: 5, scale: 2, null: false
  t.timestamps
end

add_index :votes, [:user_id, :documentation_task_id], unique: true
```
- On create, snapshot `user.vote_weight` into `weight`
- Counter cache on `draft_version.votes_count`

### 6. Feedback Model
```
create_table :feedbacks do |t|
  t.references :user, null: false, foreign_key: true
  t.references :draft_version, null: false, foreign_key: true
  t.text :body, null: false
  t.timestamps
end

add_index :feedbacks, [:user_id, :draft_version_id], unique: true
```

### 7. Model Associations
- `User` has_many :votes, has_many :feedbacks
- `Project` has_many :documentation_tasks
- `DocumentationTask` belongs_to :project, has_many :draft_versions, has_many :votes, belongs_to :winning_version (optional)
- `DraftVersion` belongs_to :documentation_task, has_many :votes, has_many :feedbacks
- `Vote` belongs_to :user, :documentation_task, :draft_version
- `Feedback` belongs_to :user, :draft_version

### 8. Seeds
- Create the Rails project record
- Create a sample user, task, draft versions, and votes for development

## Output
Complete database schema with all models, validations, associations, enums, indexes, and seed data.

## Estimated Complexity
Medium — straightforward schema but many models with careful constraints.

## Notes
- The `winning_version` FK on DocumentationTask creates a circular dependency with DraftVersion. The migration for DocumentationTask should initially omit this column, and a separate migration adds it after DraftVersion table exists. Or use a single migration that creates both tables then adds the FK.
- Counter cache on `votes_count` requires `counter_cache: true` on the Vote belongs_to :draft_version association.
