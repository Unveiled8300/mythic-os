# Phase: Deployment
> Loaded when: deploy, ship, production, staging keywords detected.

## DevOps Sequence: ENV-SETUP → PIPELINE → STAGE → SHIP → MONITOR

## Key Rules
- Staging QA PASS is a HARD prerequisite for production deploy
- Run database migrations BEFORE deploying new application code
- Rollback plan must be documented before deploying
- Smoke test immediately after production deploy: app loads, health endpoint, auth route, primary action
- If smoke test fails: execute rollback, notify Founder immediately

## Required Artifacts
- `.env.example` — all vars listed, no real secrets
- `DEPLOY.md` — rollback procedure, secrets vault strategy, monitoring config
- CI/CD pipeline: lint → test → deploy (GitHub Actions or platform native)

## Incident Response
- P1 (site down/data loss): rollback first, investigate after
- P2 (core feature broken): hotfix if <15min, else rollback
- P1/P2 mandatory: file error-record via Storyteller after resolution
