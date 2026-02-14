# DocsTown

This file provides guidance to AI coding agents working with this repository.

## What is DocsTown?

DocsTown is a community-driven documentation tool for open source projects. It discovers undocumented methods in a codebase, generates multiple draft documentation versions using LLMs, lets the community vote on the best version, and submits the winning documentation as a pull request. Currently targeting Ruby on Rails (`rails/rails`).

## Development Commands

### Setup and Server
```bash
bin/setup              # Initial setup (installs gems, creates DB, loads schema)
bin/rails server       # Start development server (port 3000)
bin/rails db:seed      # Load seed data for UI testing
```

Development URL: http://localhost:3000
Login via GitHub OAuth. Seed user `c-sonnier` is admin.

### Testing
```bash
bin/rails test                          # Run all tests
bin/rails test test/path/file_test.rb   # Run single test file
bin/rails test:system                   # Run system tests
```

### Database
```bash
bin/rails db:seed      # Seed sample data (idempotent)
bin/rails db:migrate   # Run migrations
bin/rails db:reset     # Drop, create, load schema, seed
```

## Architecture Overview

### Authentication

GitHub OAuth via OmniAuth:
- Sessions managed via `session[:user_id]`
- `Current.user` set in `ApplicationController` before_action
- Three roles: `voter` (0), `maintainer` (1), `admin` (2)
- Admin and maintainer access gated by `require_maintainer` in `ApplicationController`

### Core Domain Models

**Project** — A GitHub repository to document (e.g., `rails/rails`)
- Has many documentation tasks
- Tracks `last_scanned_at` for discovery scheduling

**DocumentationTask** — A single undocumented method to document
- Belongs to a project
- Stores `method_signature`, `source_code`, `source_file_path`, `class_context`
- Status enum: `drafting` → `voting` → `pending_review` → `submitted` → `merged`
- PR tracking: `pr_status` (pending/open/merged/closed), `pr_url`
- Consensus requires 20+ votes with >50% for the leading version

**DraftVersion** — An LLM-generated documentation draft
- Three per task, labeled A/B/C
- Each from a different provider: `claude`, `openai`, `kimi`
- Tracks `votes_count` (counter cache) and `winner` flag
- Only one winner per task (enforced by unique partial index)

**User** — GitHub-authenticated user
- Identified by `github_uid`
- Roles: `voter`, `maintainer`, `admin`
- Has many votes

**Vote** — A user's preference for a draft version
- One vote per user per task (unique index)
- Belongs to both `documentation_task` and `draft_version`

### Pipeline (Background Jobs)

The documentation pipeline runs as a series of background jobs via Solid Queue:

1. **DiscoveryJob** — Clones the repo, parses undocumented methods, creates tasks in `drafting` status
2. **DraftPickupJob** — Finds `drafting` tasks, generates 3 draft versions via LLMs, moves to `voting`
3. **Consensus** — When a task hits 20+ votes with >50% leader, it moves to `pending_review`
4. **Admin Review** — Maintainer/admin approves or rejects with a note
5. **PrSubmissionJob** — Inserts winning docs into source, submits PR to GitHub
6. **PrStatusCheckJob** — Polls GitHub for PR merge status, updates task accordingly
7. **WeeklyDigestJob** — Sends digest emails to opted-in users

### Services

- `Discovery::RepoManager` — Clones/manages local repo copies
- `Discovery::MethodParser` — Parses Ruby files for undocumented methods
- `Github::PrSubmitter` — Creates branches, commits docs, opens PRs
- `Github::DocInserter` — Inserts RDoc above method definitions in source files

### Key Patterns

- **Current attributes**: `Current.user` for request-scoped user
- **State machine**: `DocumentationTask` uses manual transition methods (`start_voting!`, `finalize_consensus!`, `approve!`, `reject!`, `mark_merged!`) with guard clauses
- **Counter cache**: `votes_count` on `DraftVersion` maintained manually
- **Importmap**: JavaScript via importmap-rails, no bundler
- **Propshaft**: Asset pipeline (not Sprockets)
- **Solid Queue**: Database-backed job queue (no Redis)

## Coding Style

- Ruby: Rails conventions, DHH style
- Keep methods short and readable
- No premature abstractions
- Prefer editing existing files over creating new ones
- Don't add comments, docstrings, or type annotations to unchanged code
- Git: conventional commit prefixes (`feat`, `fix`, `chore`, `refactor`, `test`, `docs`)
