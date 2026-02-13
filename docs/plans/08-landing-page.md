# Plan 08: Landing Page & Public UI

## Goal
Build the landing page that explains DocsTown and drives sign-ups, plus the user dashboard.

## Prerequisites
- Plan 00 (Project Setup — Tailwind, application layout)
- Plan 02 (Authentication)

## Design References
All views in this plan must follow the Playful Geometric design system:
- **`STYLE_GUIDE.md`** — Design tokens, component specs, animation patterns, CSS custom properties
- **`mockups/landing.html`** — Complete landing page implementation with hero, how-it-works, problem/solution, stats, comparison table, use cases, CTA, and footer. This is the most complete reference for the design system in action.
- **`mockups/dashboard.html`** — Dashboard layout with stats row, quick actions, voting history table, achievement badges

## Tasks

### 1. Root Route Split
```ruby
# Authenticated users see dashboard, visitors see landing page
authenticated -> { Current.user.present? } do
  root to: "dashboards#show", as: :authenticated_root
end
root to: "pages#landing"
```

Or simpler: a single `PagesController#landing` that renders the dashboard partial for logged-in users and the landing page for visitors.

### 2. Landing Page (`GET /`)
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

**Stats approach:** Use `Rails.cache.fetch("site_stats", expires_in: 1.hour)` to cache aggregate queries. No separate model or periodic job needed for MVP — a cached query is simple and sufficient.

### 3. User Dashboard (`GET /dashboard`)
- Require authentication
- Show user's voting activity:
  - Total votes cast
  - Votes that aligned with consensus (winning picks)
  - Recent voting history with task links
- Quick links to open tasks that need votes
- Standard page load — no Turbo Frames lazy-loading for MVP

### 4. Responsive Layout
- Ensure all pages work on mobile, tablet, and desktop
- Navigation: hamburger menu on mobile, full nav on desktop
- Task detail page: stack versions vertically on mobile

### 5. Flash Messages & Error Pages
- Styled flash messages (success, error, notice) using Tailwind
- Custom 404 and 500 error pages matching the DocsTown design

### 6. Tests
- System test for landing page rendering
- System test for dashboard with voting history
- Verify unauthenticated users see sign-in CTA
- Verify authenticated users are routed to dashboard
- Test stats caching

## Output
Polished landing page that explains the product and a user dashboard showing voting activity.

## Estimated Complexity
Low-Medium — mostly view/template work with Tailwind styling.

## Notes
- The landing page is the first thing visitors see — it should clearly communicate the value proposition
- The landing page mockup (`mockups/landing.html`) is a complete static implementation — extract its structure into Rails ERB views and replace hardcoded content with dynamic data
