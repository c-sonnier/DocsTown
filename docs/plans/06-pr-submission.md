# Plan 06: PR Submission Flow

## Goal
Build the system that allows maintainers to review winning versions and automatically submit PRs to `rails/rails` via the GitHub API.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model)
- Plan 02 (Authentication — maintainer role)
- Plan 05 (Voting System — tasks reach `pending_review` status)

## Tasks

### 1. Admin Review Interface (`GET /admin/tasks`)
- List tasks in `pending_review` status
- For each task, show:
  - Method signature and source file
  - Winning version content
  - Vote breakdown (totals per version)
  - Voter feedback on the winning version
- Two actions:
  - **Approve** — triggers PR submission
  - **Reject** — requires a note, sends task back to voting or closes it

### 2. Admin Task Detail (`GET /admin/tasks/:id`)
- Full view of the task with all context
- All three versions displayed with vote counts
- All feedback displayed
- Winning version highlighted
- Approve / Reject buttons with confirmation

### 3. Admin Controller
Create `Admin::TasksController`:
- `index` — list pending_review tasks
- `show` — detailed view
- `approve` — trigger PR submission
  - Update status: `pending_review` → `approved`
  - Enqueue `PrSubmissionJob`
- `reject` — send back with note
  - Require `reviewer_note` param
  - Update status: `pending_review` → `rejected` (or back to `voting` for re-evaluation)
- Require `maintainer` role for all actions

### 4. GitHub PR Service
Create `GitHubService::PrSubmitter`:
- Use Octokit gem with a DocsTown service account token
- Steps:
  1. Ensure DocsTown fork of `rails/rails` exists (create if not)
  2. Get latest commit SHA from Rails main branch
  3. Create a new branch: `docstown/add-docs-{method-name}-{task-id}`
  4. Read the existing source file from Rails repo
  5. Insert the winning documentation into the correct location in the file
  6. Create a commit on the new branch via GitHub API (tree + commit + ref)
  7. Open a PR from the DocsTown fork branch to `rails/rails:main`
  8. PR title: "Add documentation for `MethodSignature`"
  9. PR body: mention DocsTown, link to task, credit voters
  10. Store `pr_url` on the DocumentationTask
  11. Update status: `approved` → `submitted`

### 5. Documentation Insertion Logic
Create `GitHubService::DocInserter`:
- Given a source file and method signature, determine where to insert the RDoc comment
- Parse the file to find the exact method definition line
- Insert the documentation comment block immediately before the method
- Handle edge cases:
  - Methods with existing partial documentation
  - Methods defined in multiple ways (`def`, `define_method`)
  - Indentation matching

### 6. PR Status Tracking Job
Create `PrStatusCheckJob`:
- Poll GitHub API for PR status on submitted tasks
- Update `pr_status` field: `open` → `merged` or `closed`
- Update task status accordingly: `submitted` → `merged` or `closed`
- Run on a schedule (e.g., every 6 hours) or via GitHub webhooks

### 7. PR Submission Job
Create `PrSubmissionJob`:
- Takes a `documentation_task_id`
- Calls `GitHubService::PrSubmitter`
- Handle failures: retry with backoff, alert maintainers on persistent failure
- Runs on the `github` queue

### 8. Tests
- Test PrSubmitter with mocked Octokit responses
- Test DocInserter with sample Ruby files
- Test admin controller authorization
- Test approve/reject flows
- Test PR status tracking updates

## Output
End-to-end flow: maintainer approves → PR automatically submitted to rails/rails → status tracked.

## Estimated Complexity
High — GitHub API interactions (fork, branch, commit, PR) are multi-step and error-prone. Documentation insertion into existing source files is tricky.

## Key Risks
- **Doc insertion accuracy:** Getting the exact right location in a source file to insert documentation requires careful parsing.
- **Git conflicts:** If Rails main branch moves between task creation and PR submission, the file may have changed. Need to handle merge conflicts.
- **GitHub API rate limits:** Octokit calls are rate-limited. Need to handle 403/429 responses.
- **Fork management:** Maintaining a fork that stays in sync with upstream requires periodic syncing.

## Open Decisions
- **Fork strategy:** Persistent fork (simpler branch management) vs on-the-fly (cleaner but more API calls). Recommend persistent fork.
- **PR template:** Exact wording of PR description and attribution format.
- **Webhook vs polling:** For PR status tracking. Polling is simpler for MVP; webhooks are more responsive.
