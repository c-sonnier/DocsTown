# Plan 08: Landing Page & Public UI

## Goal
Build the landing page that explains DocsTown and drives sign-ups, plus the user dashboard.

## Prerequisites
- Plan 00 (Project Setup — Tailwind, application layout)
- Plan 02 (Authentication)

## Tasks

### 1. Landing Page (`GET /`)
- Hero section:
  - Tagline: "It takes a town to raise great docs."
  - Brief explanation of how DocsTown works
  - "Sign in with GitHub" CTA button
- How It Works section (3-step visual):
  1. "AI writes three versions of missing documentation"
  2. "You read and vote on the best one"
  3. "Winners become pull requests to open source projects"
- Stats section (dynamic):
  - Total tasks created
  - Total votes cast
  - PRs submitted / merged
- Currently targeting: "Ruby on Rails" with Rails logo
- Footer with links

### 2. User Dashboard (`GET /dashboard`)
- Require authentication
- Show user's voting activity:
  - Total votes cast
  - Votes that aligned with consensus (winning picks)
  - Recent voting history with task links
- Quick links to open tasks that need votes

### 3. Responsive Layout
- Ensure all pages work on mobile, tablet, and desktop
- Navigation: hamburger menu on mobile, full nav on desktop
- Task detail page: stack versions vertically on mobile, side-by-side on desktop

### 4. Flash Messages & Error Pages
- Styled flash messages (success, error, notice) using Tailwind
- Custom 404 and 500 error pages matching the DocsTown design

### 5. Tests
- System test for landing page rendering
- System test for dashboard with voting history
- Verify unauthenticated users see sign-in CTA
- Verify authenticated users see navigation links

## Output
Polished landing page that explains the product and a user dashboard showing voting activity.

## Estimated Complexity
Low-Medium — mostly view/template work with Tailwind styling.

## Notes
- The landing page is the first thing visitors see — it should clearly communicate the value proposition
- Stats should use counter caches or periodic calculation to avoid expensive queries on every page load
- Consider using Turbo Frames for the dashboard to lazy-load sections
