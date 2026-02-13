# Plan 07: Email Notifications (Weekly Digest)

## Goal
Send a weekly email digest to opted-in users summarizing documentation activity and linking to open tasks.

## Prerequisites
- Plan 00 (Project Setup — Action Mailer + Solid Queue)
- Plan 01 (Data Model — User `digest_opted_in` field)
- Plan 02 (Authentication — users exist)
- Plan 05 (Voting System — tasks to report on)

## Design References
The settings page in this plan must follow the Playful Geometric design system:
- **`STYLE_GUIDE.md`** — Design tokens, component specs (inputs, toggle switches, buttons)
- **`mockups/settings.html`** — Settings layout with profile card, email input, digest toggle, danger zone, success toast

## Tasks

### 1. Mailer Configuration
- Configure Action Mailer for production delivery (SendGrid, Postmark, or SES — TBD)
- Configure development environment to use `letter_opener` gem for local preview
- Set default `from` address: `digest@docstown.org` (or similar)

### 2. Digest Mailer
Create `DigestMailer`:
- `weekly_digest(user)` method
- Gather stats for the past week:
  - Count of new documentation tasks available for voting
  - Count of tasks that reached consensus and were submitted as PRs
  - Count of tasks with PRs that were merged
- Include direct links to open voting tasks
- HTML email with clean, simple design
- Plain text alternative
- Skip sending if there is no new activity (avoid empty emails)

### 3. Digest Job
Create `WeeklyDigestJob`:
- Query all users where `digest_opted_in: true` and `email` is present
- For each user, enqueue `DigestMailer.weekly_digest(user).deliver_later`
- Schedule: Monday mornings (configure via Solid Queue recurring schedule)
- Idempotency: track `last_digest_sent_at` on User to prevent double-sends if the job runs twice in one week

### 4. User Profiles Controller (`GET /profile`, `PATCH /profile`)
Routes:
```ruby
resource :profile, only: [:show, :update]
```

Create `ProfilesController`:
- `show` — display current settings (digest toggle, email)
- `update` — update digest preference and email
- Require authentication

This is a user editing their own profile, not a generic "settings" concept.

### 5. Unsubscribe Flow
- Include a one-click unsubscribe link in digest emails
- Use Rails' built-in `X-List-Unsubscribe` header and `X-List-Unsubscribe-Post` header for email client integration
- `GET /unsubscribe/:token` renders a confirmation page ("You have been unsubscribed")
- `POST /unsubscribe/:token` performs the actual opt-out (state change on POST, not GET, per HTTP semantics)
- Token generated via `ActiveSupport::MessageVerifier`
- No authentication required for unsubscribe (CAN-SPAM compliance)

### 6. Tests
- Test digest content includes correct stats
- Test digest only sent to opted-in users with emails
- Test digest skipped when no new activity
- Test idempotency (double job run does not double-send)
- Test unsubscribe token generation and verification
- Test unsubscribe POST opts out user
- Test unsubscribe GET renders confirmation without performing opt-out
- Test mailer preview for development

## Output
Weekly email digest sent to opted-in users with activity summary and direct links to vote.

## Estimated Complexity
Low-Medium — Action Mailer is well-established. Main work is the digest content aggregation and unsubscribe flow.

## Notes
- Use `ActionMailer::Preview` for easy development testing
- Batch delivery: process users in batches of 100 to avoid overwhelming the mail service
- `last_digest_sent_at` column needs to be added to the users table (add to Plan 01 migration or as a separate migration here)
