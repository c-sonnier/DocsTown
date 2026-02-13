# Plan 01: Data Model & Migrations

## Goal
Create all core database tables, models, associations, validations, enums, and state transition logic.

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
  t.integer :role, default: 0, null: false  # enum: voter=0, maintainer=1
  t.boolean :digest_opted_in, default: true, null: false
  t.timestamps
end
```
- Enum for `role`: `{ voter: 0, maintainer: 1 }`
- Validations: presence of `github_uid`, `github_username`; uniqueness of `github_uid`

Note: `vote_weight` deferred — all votes count equally for MVP. Add weighted voting when there is a policy for assigning weights.

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
  t.string :pr_url
  t.integer :pr_status  # enum: pending=0, open=1, merged=2, closed=3
  t.text :reviewer_note
  t.timestamps
end

add_index :documentation_tasks, [:project_id, :method_signature], unique: true
add_index :documentation_tasks, :status
add_index :documentation_tasks, :pr_status
```
- Enum for `status`: `{ drafting: 0, voting: 1, pending_review: 2, submitted: 3, merged: 4 }`
- Enum for `pr_status`: `{ pending: 0, open: 1, merged: 2, closed: 3 }`

Five states instead of eight:
- `drafting` — LLM drafts being generated
- `voting` — open for community votes
- `pending_review` — consensus reached, awaiting maintainer review
- `submitted` — PR opened on GitHub
- `merged` — PR merged (terminal state)

Rejection is handled by transitioning back to `voting` with a `reviewer_note`, not a separate state. Closing a task is a soft-delete concern for later.

### 4. State Transition Logic on DocumentationTask
Define explicit transition methods on the model with guard clauses:

```ruby
class DocumentationTask < ApplicationRecord
  def start_voting!
    raise InvalidTransition unless drafting?
    update!(status: :voting)
  end

  def finalize_consensus!
    raise InvalidTransition unless voting?
    raise "No consensus" unless consensus_reached?
    update!(status: :pending_review)
  end

  def approve!
    raise InvalidTransition unless pending_review?
    update!(status: :submitted)
  end

  def reject!(note:)
    raise InvalidTransition unless pending_review?
    update!(status: :voting, reviewer_note: note)
  end

  def mark_merged!
    raise InvalidTransition unless submitted?
    update!(status: :merged, pr_status: :merged)
  end
end
```

No state machine gem — these methods are the state machine. The model enforces valid transitions. Controllers call one method.

### 5. DraftVersion Model
```
create_table :draft_versions do |t|
  t.references :documentation_task, null: false, foreign_key: true
  t.integer :label, null: false  # enum: a=0, b=1, c=2
  t.string :provider, null: false  # internal only: claude, openai, kimi
  t.text :content, null: false
  t.text :prompt_used
  t.integer :votes_count, default: 0, null: false  # manually managed counter
  t.boolean :winner, default: false, null: false
  t.timestamps
end

add_index :draft_versions, [:documentation_task_id, :label], unique: true
add_index :draft_versions, :documentation_task_id, unique: true, where: "winner = true",
          name: "index_draft_versions_on_task_id_winner"
```
- Enum for `label`: `{ a: 0, b: 1, c: 2 }`
- The `winner` boolean replaces the circular `winning_version` FK on DocumentationTask
- Partial unique index ensures at most one winner per task
- `votes_count` is manually managed (not `counter_cache: true`) because vote changes require decrement on old version + increment on new version

### 6. Vote Model
```
create_table :votes do |t|
  t.references :user, null: false, foreign_key: true
  t.references :documentation_task, null: false, foreign_key: true
  t.references :draft_version, null: false, foreign_key: true
  t.timestamps
end

add_index :votes, [:user_id, :documentation_task_id], unique: true
```
- One vote per user per task (enforced by unique index)
- No `weight` column — all votes equal for MVP
- Custom counter management: when a vote is created or changed, manually update `votes_count` on affected DraftVersions via model callbacks or controller logic

### 7. Model Associations
- `User` has_many :votes
- `Project` has_many :documentation_tasks
- `DocumentationTask` belongs_to :project, has_many :draft_versions, has_many :votes
- `DraftVersion` belongs_to :documentation_task, has_many :votes
- `Vote` belongs_to :user, :documentation_task, :draft_version
- `DocumentationTask#winning_version` — `draft_versions.find_by(winner: true)`
- `DocumentationTask#leading_version` — `draft_versions.order(votes_count: :desc).first`

### 8. Consensus Logic on DocumentationTask
This belongs on the model, not in a service:

```ruby
class DocumentationTask < ApplicationRecord
  CONSENSUS_VOTE_THRESHOLD = 20
  CONSENSUS_PERCENTAGE_THRESHOLD = 50

  def consensus_reached?
    return false if votes.count < CONSENSUS_VOTE_THRESHOLD
    leading_version_percentage > CONSENSUS_PERCENTAGE_THRESHOLD
  end

  def leading_version
    draft_versions.order(votes_count: :desc).first
  end

  def leading_version_percentage
    return 0 if votes.count.zero?
    (leading_version.votes_count.to_f / votes.count * 100).round(1)
  end
end
```

### 9. Prompt Building on DocumentationTask
The prompt is built from the task's own attributes — it belongs on the model:

```ruby
class DocumentationTask < ApplicationRecord
  def build_prompt
    # Compose prompt from method_signature, source_code, class_context
    # Include Rails RDoc style conventions
    # Return a string ready to send to any LLM client
  end
end
```

### 10. Seeds
- Create the Rails project record
- Create a sample user, task, draft versions, and votes for development

## Output
Complete database schema with all models, validations, associations, enums, state transitions, indexes, and seed data.

## Estimated Complexity
Medium — straightforward schema but many models with careful constraints.

## Notes
- Feedback model deferred from MVP. If qualitative input is needed, add an optional `feedback` text column on Vote later.
- The `votes_count` on DraftVersion is manually managed, not via `counter_cache: true`, because vote changes (user switches from Version A to B) require decrementing the old version and incrementing the new one. `counter_cache` only handles create/destroy.
