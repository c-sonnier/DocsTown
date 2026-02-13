# DocsTown Implementation Plans

## Overview

These plans break down the DocsTown MVP into 10 workstreams, ordered by dependency. Each plan is self-contained with goals, prerequisites, tasks, and complexity estimates.

## Plan Index

| # | Plan | Description | Complexity | Prerequisites |
|---|------|-------------|------------|---------------|
| 00 | [Project Setup](00-project-setup.md) | Rails 8 app, dependencies, infrastructure | Medium | None |
| 01 | [Data Model](01-data-model.md) | All tables, models, associations, seeds | Medium | 00 |
| 02 | [Authentication](02-authentication.md) | GitHub OAuth sign-in/sign-out | Low-Medium | 00, 01 |
| 03 | [Discovery Pipeline](03-discovery-pipeline.md) | Clone Rails, parse Ruby, find undocumented methods | High | 00, 01 |
| 04 | [Draft Generation](04-draft-generation.md) | LLM integration (Claude, GPT, Kimi) | Medium | 00, 01, 03 |
| 05 | [Voting System](05-voting-system.md) | Browse tasks, vote, consensus detection | Medium-High | 00, 01, 02 |
| 06 | [PR Submission](06-pr-submission.md) | Maintainer review, auto-submit PRs to Rails | High | 00, 01, 02, 05 |
| 07 | [Email Notifications](07-email-notifications.md) | Weekly digest, unsubscribe flow | Low-Medium | 00, 01, 02, 05 |
| 08 | [Landing Page & UI](08-landing-page.md) | Marketing page, dashboard, polish | Low-Medium | 00, 02 |
| 09 | [Deployment](09-deployment.md) | Production hosting, CI/CD, monitoring | Medium | All |

## Dependency Graph

```
00 Project Setup
├── 01 Data Model
│   ├── 02 Authentication
│   │   ├── 05 Voting System
│   │   │   ├── 06 PR Submission
│   │   │   └── 07 Email Notifications
│   │   └── 08 Landing Page & UI
│   ├── 03 Discovery Pipeline
│   │   └── 04 Draft Generation
│   └───────────────────────────── 09 Deployment (depends on all)
```

## Recommended Execution Order

### Phase 1: Foundation
1. **00 Project Setup** — Get the Rails app running
2. **01 Data Model** — Create all tables and models

### Phase 2: Core Features (can be parallelized)
3. **02 Authentication** — GitHub OAuth
4. **03 Discovery Pipeline** — Rails repo parsing (can start in parallel with 02)

### Phase 3: User Experience
5. **05 Voting System** — The core product loop (depends on 02)
6. **04 Draft Generation** — LLM integration (depends on 03)
7. **08 Landing Page & UI** — Public-facing pages (can start in parallel with 05)

### Phase 4: Completion
8. **06 PR Submission** — GitHub PR automation (depends on 05)
9. **07 Email Notifications** — Weekly digest (depends on 05)

### Phase 5: Ship
10. **09 Deployment** — Get it live

## Design System & Mockups

All UI work must follow the **Playful Geometric** design system. Before building any screens, read these references:

- **`STYLE_GUIDE.md`** — Design tokens (colors, typography, spacing, shadows), component specs (buttons, cards, inputs), animation patterns, and CSS custom properties. This is the single source of truth for visual design decisions.
- **`mockups/`** — Static HTML mockups for every major screen, organized by user flow. Use these as the implementation target when building views.

| Mockup | File | Relevant Plans |
|--------|------|----------------|
| Gallery (all screens) | `mockups/index.html` | — |
| Landing Page | `mockups/landing.html` | 08 |
| Tasks Index | `mockups/tasks-index.html` | 05 |
| Task Detail | `mockups/tasks-detail.html` | 05 |
| Dashboard | `mockups/dashboard.html` | 08 |
| Settings | `mockups/settings.html` | 07 |
| Admin Review | `mockups/admin-review.html` | 06 |

When implementing views, match the mockup's layout, component styles, and interactions as closely as possible. Extract shared CSS into Tailwind utilities or partials, but keep the design tokens and visual language consistent.

## Architecture Notes

- **Fat models, skinny controllers**: Domain logic lives on the models. Consensus checking, state transitions, prompt building — these are model concerns, not service objects. Extract to services only for external integrations (LLM API clients, GitHub API operations, repo cloning).
- **Background jobs** for all external API calls: LLM APIs, GitHub API, email delivery
- **Hotwire** for interactivity: Turbo for form submissions and page updates. Real-time Turbo Streams deferred to post-MVP.
- **No JavaScript framework**: Stimulus for the small amount of client-side behavior needed
- **Single job queue** for MVP: one `default` queue until traffic data justifies separation
- **Current attributes** for request-scoped state: `Current.user` available everywhere (models, jobs, mailers)

## Error Handling Strategy

All plans share a unified approach to external service failures:

- **Retry policy**: 3 retries with exponential backoff (1s, 5s, 25s) for all external API calls (LLM, GitHub, email)
- **Job failures**: Solid Queue's built-in retry mechanism. Failed jobs stay in the queue with backoff. No dead letter queue for MVP — monitor via Solid Queue dashboard (Mission Control).
- **Graceful degradation**: If one LLM provider fails after retries, create the task with available drafts (2 of 3 is acceptable). If GitHub API is down, leave task in `approved` status and retry later.
- **Logging**: Use `Rails.logger` with structured tags for all external calls. No separate logging infrastructure for MVP.
- **Alerting**: Error tracking service (Sentry/Honeybadger) captures unhandled exceptions. No custom alerting for MVP.
