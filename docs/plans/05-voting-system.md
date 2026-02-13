# Plan 05: Voting System

## Goal
Build the core voting experience: browsing tasks, reading drafts, casting votes, leaving feedback, and detecting consensus.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — Vote, Feedback, DraftVersion)
- Plan 02 (Authentication — users must be signed in to vote)

## Tasks

### 1. Tasks Index Page (`GET /tasks`)
- List all documentation tasks with status badges
- Default filter: show `voting` status tasks
- Filterable by status: voting, pending_review, submitted, merged
- Sortable by: newest, most votes, closest to consensus
- Pagination (25 per page)
- Show for each task:
  - Method signature
  - Source file path
  - Current vote count
  - Status badge
  - Progress toward consensus (vote count / 20 threshold)

### 2. Task Detail Page (`GET /tasks/:id`)
- **Context section:**
  - Method signature (prominently displayed)
  - Source file path with link context
  - Source code (syntax highlighted)
  - Class/module context (collapsible)
- **Draft versions section:**
  - Display all three versions (A, B, C) side by side (desktop) or stacked (mobile)
  - Render documentation content with proper formatting
  - No provider attribution visible
- **Voting section (if task status is `voting`):**
  - Radio button / card selection for choosing a version
  - Submit vote button
  - Show user's current vote if they've already voted (allow changing)
- **Feedback section:**
  - Text area per version for optional feedback
  - Show existing feedback from other users (after voting)
- **Results section (if task is past voting):**
  - Show vote tallies
  - Highlight winning version
  - Show PR status if submitted

### 3. Vote Controller (`POST /tasks/:id/vote`)
- Require authentication
- Validate task is in `voting` status
- Find or update vote (upsert based on user + task uniqueness)
- Snapshot user's `vote_weight` into vote's `weight`
- Update counter caches on DraftVersions
- After vote, check consensus:
  - Total votes >= 20 AND top version has > 50% of votes
  - If consensus reached → update task status to `pending_review`, set `winning_version`
- Respond with Turbo Stream to update vote counts and status without full page reload

### 4. Feedback Controller (`POST /draft_versions/:id/feedback`)
- Require authentication
- Create or update feedback (upsert based on user + draft_version uniqueness)
- Validate body presence
- Respond with Turbo Stream

### 5. Consensus Detection Service
Create `ConsensusChecker`:
- Input: a DocumentationTask
- Calculate total votes (sum of weights for future, count for MVP)
- Calculate per-version vote totals
- Apply threshold rules: total >= 20, top version > 50%
- Return: `{ reached: bool, winning_version_id:, total_votes:, percentages: {} }`
- Called after every vote to check if consensus was just reached

### 6. Turbo Streams for Live Updates
- Use Turbo Streams to update vote counts in real-time
- When a user votes, broadcast updated counts to all viewers of that task
- When consensus is reached, broadcast status change

### 7. Tests
- Test voting creates/updates Vote record correctly
- Test vote weight snapshot
- Test one-vote-per-user-per-task constraint
- Test vote changing
- Test consensus detection at various thresholds
- Test consensus not triggered below threshold
- Test feedback creation and uniqueness
- System tests for the full voting flow

## Output
Complete voting experience from browsing tasks to casting votes to consensus detection.

## Estimated Complexity
Medium-High — the UI is the most user-facing part of the app and needs to feel good. Consensus logic must be bulletproof.

## Notes
- Turbo Streams for real-time updates are a nice-to-have for MVP; polling or page refresh after vote is acceptable as a simpler first pass
- Consider optimistic locking on votes to handle race conditions in consensus checking
- The task detail page is the most important page in the app — invest in making it clear and usable
