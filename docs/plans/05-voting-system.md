# Plan 05: Voting System

## Goal
Build the core voting experience: browsing tasks, reading drafts, casting votes, and detecting consensus.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — Vote, DraftVersion, consensus logic on DocumentationTask)
- Plan 02 (Authentication — users must be signed in to vote)

## Design References
All views in this plan must follow the Playful Geometric design system:
- **`STYLE_GUIDE.md`** — Design tokens, component specs, animation patterns
- **`mockups/tasks-index.html`** — Tasks index layout, filter bar, task cards, pagination
- **`mockups/tasks-detail.html`** — Task detail layout, source code card, version cards (full-width with vote button on right), feedback section, remove vote flow

## Tasks

### 1. Model Scopes on DocumentationTask
Define scopes for filtering and sorting the tasks index:

```ruby
class DocumentationTask < ApplicationRecord
  scope :by_status, ->(status) { where(status: status) }
  scope :newest, -> { order(created_at: :desc) }
  scope :most_votes, -> { order(Arel.sql("(SELECT COUNT(*) FROM votes WHERE votes.documentation_task_id = documentation_tasks.id) DESC")) }
end
```

"Closest to consensus" sorting deferred — it requires a complex query and the product value is unclear for MVP. Sort by newest and most votes is sufficient.

### 2. Tasks Index Page (`GET /tasks`)
- List all documentation tasks with status badges
- Default filter: show `voting` status tasks
- Filterable by status: voting, pending_review, submitted, merged
- Sortable by: newest, most votes
- Pagination (25 per page)
- Show for each task:
  - Method signature
  - Source file path
  - Current vote count (from counter on leading DraftVersion)
  - Status badge
  - Progress toward consensus (vote count / 20 threshold)

### 3. Task Detail Page (`GET /tasks/:id`)
- **Context section:**
  - Method signature (prominently displayed)
  - Source file path with link context
  - Source code (syntax highlighted, dark bg)
  - Class/module context (collapsible card)
- **Draft versions section:**
  - Display all three versions (A, B, C) as **full-width stacked cards** with vote button on the right (see `mockups/tasks-detail.html`)
  - On mobile, vote button drops below the content
  - Render documentation content with proper formatting
  - No provider attribution visible
  - If user has already voted, highlight their selection with a border and checkmark badge
- **Voting (if task status is `voting`):**
  - Clicking the vote button on a version card selects it
  - "Remove vote" link in red below the vote button allows removing the vote entirely
  - No version pre-selected on page load
- **Results section (if task is past voting):**
  - Show vote tallies
  - Highlight winning version
  - Show PR status if submitted

### 4. Votes Controller (RESTful nested resource)
Routes:
```ruby
resources :tasks, only: [:index, :show] do
  resource :vote, only: [:create, :destroy]
end
```

Create `VotesController`:
- `create` (`POST /tasks/:task_id/vote`)
  - Require authentication
  - Validate task is in `voting` status
  - Find or update vote (upsert based on user + task uniqueness)
  - Manually manage `votes_count` counters:
    - If changing vote: decrement old DraftVersion, increment new DraftVersion
    - If new vote: increment selected DraftVersion
  - **Consensus check with locking:**
    ```ruby
    task.with_lock do
      # re-check consensus inside the lock to prevent race condition
      task.finalize_consensus! if task.consensus_reached?
    end
    ```
  - Respond with Turbo response (redirect or replace the vote section)
- `destroy` (`DELETE /tasks/:task_id/vote`)
  - Require authentication
  - Find and destroy the user's vote
  - Decrement the DraftVersion's `votes_count`
  - Respond with Turbo response

### 5. Tests
- Test voting creates Vote record correctly
- Test vote changing updates counters on both old and new DraftVersion
- Test vote removal decrements counter
- Test one-vote-per-user-per-task constraint (unique index)
- Test consensus detection at threshold (20 votes, >50%)
- Test consensus NOT triggered below threshold
- Test race condition: two simultaneous votes both hitting consensus threshold (locking prevents double transition)
- Test consensus triggers `finalize_consensus!` which sets `pending_review` and marks `winner` on DraftVersion
- System tests for the full voting flow

## Output
Complete voting experience from browsing tasks to casting votes to consensus detection.

## Estimated Complexity
Medium-High — the UI is the most user-facing part of the app and needs to feel good. Consensus logic must be bulletproof.

## Notes
- Real-time Turbo Streams broadcasting deferred to post-MVP. For now, vote counts update on page refresh or after the user's own vote action via Turbo response.
- The `with_lock` on consensus checking prevents the race condition where two simultaneous votes both detect consensus and try to transition the task. Only one will succeed inside the lock.
- Feedback feature deferred from MVP (see Plan 01 notes).
