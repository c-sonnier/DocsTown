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
| 04 | [Draft Generation](04-draft-generation.md) | LLM integration (Claude, GPT, Gemini) | Medium | 00, 01, 03 |
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

## Architecture Notes

- **Service objects** over fat models: complex logic (discovery, draft generation, PR submission, consensus) lives in dedicated service classes under `app/services/`
- **Background jobs** for all external API calls: LLM APIs, GitHub API, email delivery
- **Hotwire** for interactivity: Turbo Frames for partial page updates, Turbo Streams for real-time vote count updates
- **No JavaScript framework**: Stimulus for the small amount of client-side behavior needed
