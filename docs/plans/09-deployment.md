# Plan 09: Deployment & Operations

## Goal
Get DocsTown deployed and running in production with monitoring and operational basics.

## Prerequisites
- All previous plans (or enough to have a functional app)

## Tasks

### 1. Hosting Decision
Evaluate hosting platforms in this order:

**Kamal (Rails 8 default) — evaluate first:**
- Ships with Rails 8, the framework's own opinion on deployment
- Deploys to any VPS with Docker (DigitalOcean, Hetzner, etc.)
- Full control over the server, persistent disk for repo cloning
- More setup than managed platforms but lower ongoing cost

**Fly.io — if managed is preferred:**
- Good Rails support, persistent volumes available
- Simpler than Kamal for initial deploy
- Supports persistent disks (needed for repo cloning in Plan 03)

**Render — simplest option:**
- Simple Rails deploys, managed PostgreSQL
- Persistent disks available
- Less control but minimal ops burden

Key requirement: whichever platform is chosen MUST support persistent storage for the repo clone directory (see Plan 03 storage strategy).

### 2. Production Database
- Provision managed PostgreSQL
- Configure `DATABASE_URL` in production
- Set up automated backups
- Run Solid Queue migrations: `bin/rails solid_queue:install:migrations`
- Run Solid Cable migrations: `bin/rails solid_cable:install:migrations`

### 3. Background Jobs in Production
- Configure Solid Queue for production
- Ensure worker processes start alongside the web process
- Single `default` queue — no concurrency tuning needed for MVP
- Monitor via Mission Control (Solid Queue dashboard)

### 4. Persistent Storage for Repo Clone
- Configure persistent volume/disk for `/data/repos/` (or platform equivalent)
- Ensure the discovery job can read/write to this location
- Volume must survive deploys and restarts

### 5. Production Credentials
- Store all API keys in Rails production credentials:
  - GitHub OAuth app (production callback URL)
  - GitHub API token for PR submission
  - LLM API keys (Claude, OpenAI, Kimi)
  - Email delivery service credentials

### 6. Email Delivery Service
- Choose provider: SendGrid, Postmark, or Amazon SES
- Configure Action Mailer production settings
- Set up SPF/DKIM/DMARC for email deliverability
- Verify sending domain

### 7. Domain & SSL
- Register domain (docstown.org or similar)
- Configure DNS
- SSL certificate (typically handled by hosting platform)

### 8. Monitoring & Logging
- Application error tracking (Sentry or Honeybadger)
- Basic uptime monitoring
- Log aggregation (platform-provided is fine for MVP)
- Background job monitoring via Mission Control (Solid Queue dashboard)

### 9. CI/CD Pipeline
- GitHub Actions workflow:
  - Run tests on every push/PR
  - Run linting (RuboCop)
  - Auto-deploy to production on merge to main (optional)

### 10. Production Checklist
- [ ] Force SSL in production
- [ ] Set `SECRET_KEY_BASE`
- [ ] Set up health check endpoint
- [ ] Configure asset compilation
- [ ] Test OAuth flow with production GitHub App
- [ ] Verify background job processing (Solid Queue workers running)
- [ ] Verify Solid Queue and Solid Cable migrations ran
- [ ] Test email delivery
- [ ] Set up database migrations to run on deploy
- [ ] Verify persistent storage for repo clone survives a deploy
- [ ] Configure error tracking service

## Output
DocsTown running in production, accessible at a public URL, with monitoring and CI/CD.

## Estimated Complexity
Medium — many small configuration tasks, but mostly standard Rails deployment.

## Open Decisions
- Hosting platform choice (Kamal vs Fly.io vs Render)
- Email delivery provider
- Domain name
- Error tracking service
