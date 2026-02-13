# Plan 06: PR Submission Flow

## Goal
Build the system that allows maintainers to review winning versions and automatically submit PRs to `rails/rails` via the GitHub API.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model)
- Plan 02 (Authentication — maintainer role)
- Plan 05 (Voting System — tasks reach `pending_review` status)

## Design References
All admin views in this plan must follow the Playful Geometric design system:
- **`STYLE_GUIDE.md`** — Design tokens, component specs, animation patterns
- **`mockups/admin-review.html`** — Admin review layout, vote breakdown bars, winning version preview, approve/reject actions, rejection note flow, admin nav with yellow top border

## Tasks

### 1. Admin Review Interface
Routes:
```ruby
namespace :admin do
  resources :tasks, only: [:index, :show] do
    member do
      post :approve
      post :reject
    end
  end
end
```

### 2. Admin Tasks Controller
Create `Admin::TasksController`:
- `index` — list tasks in `pending_review` status
  - For each task, show method signature, source file, vote breakdown, winning version preview
- `show` — detailed view
  - All three versions displayed with vote counts
  - Winning version highlighted
  - Approve / Reject buttons with confirmation
- `approve` — trigger PR submission
  - Calls `task.approve!` (model state transition: `pending_review` → `submitted`)
  - Enqueue `PrSubmissionJob`
- `reject` — send back with note
  - Require `reviewer_note` param
  - Calls `task.reject!(note: params[:reviewer_note])` (model state transition: `pending_review` → `voting`)
- Require `maintainer` role for all actions (`before_action :require_maintainer`)

### 3. PR Submission Service
Create `Github::PrSubmitter` in `app/services/github/`:
- Use Octokit gem with a DocsTown service account token
- Steps:
  1. Ensure DocsTown fork of `rails/rails` exists (create if not)
  2. Sync fork with upstream main
  3. Create a new branch: `docstown/add-docs-{method-name}-{task-id}`
  4. Read the existing source file from Rails repo
  5. Insert the winning documentation at the correct location (see DocInserter below)
  6. Create a commit on the new branch via GitHub API (tree + commit + ref)
  7. Open a PR from the DocsTown fork branch to `rails/rails:main`
  8. PR title: "Add documentation for `MethodSignature`"
  9. PR body: mention DocsTown, link to task, credit voters
  10. Store `pr_url` on the DocumentationTask, set `pr_status: :open`

Use a persistent fork (simpler branch management than on-the-fly fork creation).

### 4. Documentation Inserter
This is the hardest problem in the app and needs detailed specification.

Create `Github::DocInserter` in `app/services/github/`:

**Input:** source file content (string), method signature, RDoc documentation to insert

**Algorithm:**
1. Parse the source file with Prism to build an AST
2. Walk the AST to find the target method definition node
3. Determine the exact line number of the `def` keyword
4. Determine the indentation level of the `def` line
5. Format the RDoc comment block:
   - Match the indentation of the `def` line
   - Prefix each line with `#` and appropriate spacing
   - Add a blank line before the comment if the preceding line is code
6. Insert the formatted comment block immediately before the `def` line
7. Return the modified file content as a string

**Edge cases to handle:**
- Methods that already have partial documentation (should not happen if discovery pipeline is correct, but guard against it)
- Methods defined with `def self.method_name` vs `def method_name`
- Correct indentation within nested modules/classes
- Methods at the end of a file with no trailing newline
- Methods preceded by other comments (e.g., `# :call-seq:`) — insert before any existing comment block

**What if the method no longer exists?**
- If the source file has changed since discovery and the method cannot be found, fail the job and log the error. The maintainer can re-evaluate or close the task.

### 5. PR Submission Job
Create `PrSubmissionJob`:
- Takes a `documentation_task_id`
- Calls `Github::PrSubmitter`
- Handle failures per README error handling strategy (3 retries with backoff)
- On persistent failure, log error — maintainer can retry manually from admin interface

### 6. PR Status Tracking Job
Create `PrStatusCheckJob`:
- Daily recurring job (Solid Queue schedule)
- Query all tasks in `submitted` status with `pr_status: :open`
- For each, check PR status via Octokit
- Update `pr_status` field: `open` → `merged` or `closed`
- If merged, call `task.mark_merged!`
- Polling only — no webhooks for MVP

### 7. Tests
- Test `Github::PrSubmitter` with mocked Octokit responses
- Test `Github::DocInserter` with sample Ruby files:
  - Simple method insertion
  - Nested class/module indentation
  - Method that has moved or been deleted
  - Various `def` styles (`def self.foo`, `def foo(bar, baz)`)
- Test admin controller authorization (maintainer-only access)
- Test approve/reject flows and state transitions
- Test PR status tracking updates

## Output
End-to-end flow: maintainer approves → PR automatically submitted to rails/rails → status tracked.

## Estimated Complexity
High — GitHub API interactions (fork, branch, commit, PR) are multi-step and error-prone. Documentation insertion into existing source files requires careful parsing.

## Key Risks
- **Doc insertion accuracy:** Getting the exact right location and indentation is the hardest problem. Invest heavily in tests with real Rails source file samples.
- **Stale source files:** If Rails main branch moves between discovery and PR submission, the file may have changed. DocInserter must handle this gracefully (method not found → fail and log).
- **GitHub API rate limits:** Octokit calls are rate-limited. The error handling strategy (3 retries with backoff) applies here.
- **Fork management:** Persistent fork needs periodic syncing with upstream. Sync before each PR creation.
