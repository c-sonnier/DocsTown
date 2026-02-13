# Plan 00: Project Setup & Infrastructure

## Goal
Initialize the Rails 8 application with all foundational dependencies, database configuration, and development tooling.

## Prerequisites
- None (this is the first plan)

## Tasks

### 1. Generate Rails 8 Application
- `rails new DocsTown --database=postgresql --css=tailwind --skip-jbuilder`
- Use Hotwire (Turbo + Stimulus) — included by default in Rails 8
- Use Solid Queue for background jobs (Rails 8 default)
- Use Tailwind CSS for styling

### 2. Database Setup
- Configure PostgreSQL in `config/database.yml` for development, test, and production
- Create development and test databases

### 3. Core Gem Dependencies
Add to `Gemfile`:
- `omniauth` + `omniauth-github` — GitHub OAuth
- `octokit` — GitHub API client for PR submission
- Standard HTTP clients for LLM APIs (or use provider gems if stable)
- `pg` — PostgreSQL adapter (included by default)

### 4. Solid Queue Configuration
- Configure Solid Queue as the Active Job backend
- Set up queue definitions:
  - `default` — general jobs
  - `discovery` — Rails repo parsing
  - `drafts` — LLM draft generation
  - `github` — PR submission and status polling
  - `mailers` — email delivery

### 5. Environment & Credentials
- Set up Rails credentials structure for:
  - GitHub OAuth app ID and secret
  - GitHub API token (for PR submission)
  - Claude API key
  - OpenAI API key
  - Gemini API key
- Create `.env.example` documenting all required environment variables

### 6. Development Tooling
- Configure RuboCop with Rails cops
- Set up RSpec or Minitest (match Rails conventions — Minitest)
- Add `factory_bot_rails` and `faker` for test data
- Configure CI-ready test setup

### 7. Basic Application Layout
- Set up application layout with Tailwind
- Create a simple navigation partial (logo, sign in/out, links)
- Configure flash message rendering

## Output
A runnable Rails 8 app with all dependencies installed, database created, and background job infrastructure ready.

## Estimated Complexity
Medium — mostly configuration, but several moving parts to get right.

## Open Decisions
- **CSS framework:** PRD says "TBD (Tailwind or similar)" — recommending Tailwind since it's well-supported in Rails 8.
- **Test framework:** Minitest (Rails default) vs RSpec. Recommending Minitest to stay conventional.
- **Ruby version:** Should target Ruby 3.3+ for Rails 8 compatibility.
