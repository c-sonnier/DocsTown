# Plan 07: Email Notifications (Weekly Digest)

## Goal
Send a weekly email digest to opted-in users summarizing documentation activity and linking to open tasks.

## Prerequisites
- Plan 00 (Project Setup — Action Mailer + Solid Queue)
- Plan 01 (Data Model — User `digest_opted_in` field)
- Plan 02 (Authentication — users exist)
- Plan 05 (Voting System — tasks to report on)

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
  - Count of tasks nearing consensus (e.g., 15+ votes but not yet reached threshold)
  - Count of tasks that reached consensus and were submitted as PRs
  - Count of tasks with PRs that were merged
- Include direct links to open voting tasks
- HTML email with clean, simple design
- Plain text alternative

### 3. Digest Job
Create `WeeklyDigestJob`:
- Query all users where `digest_opted_in: true`
- For each user, enqueue `DigestMailer.weekly_digest(user).deliver_later`
- Run on the `mailers` queue
- Schedule: Monday mornings (configure via Solid Queue recurring schedule)

### 4. User Settings Page (`GET /settings`)
- Toggle for email digest opt-in/opt-out
- Show current email on file
- Allow email update
- One-click unsubscribe link in digest emails (token-based, no login required)

### 5. Unsubscribe Flow
- Generate a signed unsubscribe token per user (use `ActiveSupport::MessageVerifier`)
- `GET /unsubscribe/:token` → opt out the user and show confirmation page
- No authentication required for unsubscribe (CAN-SPAM compliance)

### 6. Settings Controller
Create `SettingsController`:
- `show` — display current settings
- `update` — update digest preference and email

### 7. Tests
- Test digest content includes correct stats
- Test digest only sent to opted-in users
- Test unsubscribe token generation and verification
- Test unsubscribe flow opts out user
- Test mailer preview for development

## Output
Weekly email digest sent to opted-in users with activity summary and direct links to vote.

## Estimated Complexity
Low-Medium — Action Mailer is well-established. Main work is the digest content aggregation and unsubscribe flow.

## Notes
- Consider using `ActionMailer::Preview` for easy development testing
- The digest should be skipped for users who have no new content to see (avoid empty emails)
- Batch delivery to avoid overwhelming the mail service
