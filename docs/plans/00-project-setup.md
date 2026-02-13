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
- Use Solid Cable for Action Cable (Rails 8 default)
- Use Tailwind CSS for styling
- Target Ruby 3.3+

### 2. Database Setup
- Configure PostgreSQL in `config/database.yml` for development, test, and production
- Create development and test databases

### 3. Core Gem Dependencies
Add to `Gemfile`:
- `omniauth` + `omniauth-github` — GitHub OAuth
- `omniauth-rails_csrf_protection` — CSRF protection for OmniAuth 2.x+
- `octokit` — GitHub API client for PR submission
- Standard HTTP clients for LLM APIs (or use provider gems if stable)
- `pg` — PostgreSQL adapter (included by default)

### 4. Solid Queue Configuration
- Configure Solid Queue as the Active Job backend
- Run `bin/rails solid_queue:install:migrations` to generate queue tables
- Single `default` queue for all jobs (discovery, drafts, github, mailers)
- Add separate queues later only when traffic data justifies it

### 5. Solid Cable Configuration
- Configure Solid Cable as the Action Cable adapter
- Run `bin/rails solid_cable:install:migrations` to generate cable tables
- This is needed for any future Turbo Streams broadcasting

### 6. Environment & Credentials
- Set up Rails credentials structure for:
  - GitHub OAuth app ID and secret
  - GitHub API token (for PR submission)
  - Claude API key
  - OpenAI API key
  - Kimi (Moonshot AI) API key
- Document credential structure in a comment block at the top of `config/credentials.yml.enc`
- No `.env` file — Rails credentials is the single strategy

### 7. Development Tooling
- Configure RuboCop with Rails cops
- Minitest (Rails default) for all tests
- Add `factory_bot_rails` and `faker` for test data
- Add `letter_opener` for local email preview
- Configure CI-ready test setup

### 8. Basic Application Layout
- Set up application layout with Tailwind
- Create a simple navigation partial (logo, sign in/out, links)
- Configure flash message rendering

## Output
A runnable Rails 8 app with all dependencies installed, database created, and background job infrastructure ready.

## Estimated Complexity
Medium — mostly configuration, but several moving parts to get right.
