# Plan 09: Deployment & Operations

## Goal
Get DocsTown deployed and running in production with monitoring and operational basics.

## Prerequisites
- All previous plans (or enough to have a functional app)

## Tasks

### 1. Hosting Decision
Evaluate and choose a hosting platform:
- **Render** — simple Rails deploys, managed PostgreSQL
- **Fly.io** — good Rails support, global distribution
- **Railway** — easy deploys, built-in PostgreSQL
- **Hatchbox** — Rails-specific hosting on your own VPS
- **Heroku** — classic choice, more expensive

Recommendation: **Render** or **Fly.io** for simplicity and cost.

### 2. Production Database
- Provision managed PostgreSQL
- Configure `DATABASE_URL` in production
- Set up automated backups

### 3. Background Jobs in Production
- Configure Solid Queue for production
- Ensure worker processes start alongside the web process
- Set up queue-specific concurrency limits

### 4. Production Credentials
- Store all API keys in Rails production credentials:
  - GitHub OAuth app (production callback URL)
  - GitHub API token for PR submission
  - LLM API keys (Claude, OpenAI, Gemini)
  - Email delivery service credentials

### 5. Email Delivery Service
- Choose provider: SendGrid, Postmark, or Amazon SES
- Configure Action Mailer production settings
- Set up SPF/DKIM/DMARC for email deliverability
- Verify sending domain

### 6. Domain & SSL
- Register domain (docstown.org or similar)
- Configure DNS
- SSL certificate (typically handled by hosting platform)

### 7. Monitoring & Logging
- Application error tracking (Sentry, Honeybadger, or similar)
- Basic uptime monitoring
- Log aggregation
- Background job monitoring (Solid Queue dashboard or Mission Control)

### 8. CI/CD Pipeline
- GitHub Actions workflow:
  - Run tests on every push/PR
  - Run linting (RuboCop)
  - Auto-deploy to production on merge to main (optional)

### 9. Production Checklist
- [ ] Force SSL in production
- [ ] Set `SECRET_KEY_BASE`
- [ ] Configure CORS if needed
- [ ] Set up health check endpoint
- [ ] Configure asset compilation
- [ ] Test OAuth flow with production GitHub App
- [ ] Verify background job processing
- [ ] Test email delivery
- [ ] Set up database migrations to run on deploy

## Output
DocsTown running in production, accessible at a public URL, with monitoring and CI/CD.

## Estimated Complexity
Medium — many small configuration tasks, but mostly standard Rails deployment.

## Open Decisions
- Hosting platform choice
- Email delivery provider
- Domain name
- Error tracking service
