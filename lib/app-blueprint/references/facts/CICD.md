# CI/CD facts
Covers: GitHub Actions (service containers, secrets), Vercel CLI deployments from CI, Vercel Deployment Protection
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Deploying to Vercel from CI

### CICD-01 CLI deploys need pull, build, deploy --prebuilt and three secrets
- Trap: a CI job runs `vercel deploy --prod` and nothing else; or it builds, then deploys without `--prebuilt`.
- Reality: the documented sequence is `vercel pull --yes --environment=<env> --token=…`, `vercel build`, then `vercel deploy --prebuilt`. Production adds `--prod` to both build and deploy. The job needs `VERCEL_TOKEN`, `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` (the last two come from `.vercel/project.json`). Without `--prebuilt`, Vercel runs the build a second time.
- Detect: `vercel deploy` with no `vercel pull`/`vercel build`, no token, or no org/project IDs.
- Fix: use the three-command sequence with all three secrets set in the CI secret store.
- Source: How can I use GitHub Actions with Vercel - https://vercel.com/kb/guide/how-can-i-use-github-actions-with-vercel

### CICD-02 Git integration plus a CI deploy means two deployments
- Trap: a plan deploys from GitHub Actions while the project stays connected to Vercel's Git integration.
- Reality: both fire on the same commit, which gives duplicate builds and races on which deployment is promoted.
- Detect: a CI deploy job, and no mention of disabling Git deployments.
- Fix: set `"git": { "deploymentEnabled": false }` in `vercel.json`, or drop the CI deploy job and let the Git integration deploy.
- Source: How can I use GitHub Actions with Vercel - https://vercel.com/kb/guide/how-can-i-use-github-actions-with-vercel

### CICD-03 Protected deployments block automation and webhooks
- Trap: E2E tests, smoke checks or third-party webhooks (Stripe, Slack) run against a preview URL with no credentials.
- Reality: with Deployment Protection, Standard Protection covers every URL except production domains, including preview and generated URLs. Requests get an authentication wall. Automation must send `x-vercel-protection-bypass: <secret>`, either as a header or as a query parameter for services that cannot set headers. Vercel exposes the secret to deployments as `VERCEL_AUTOMATION_BYPASS_SECRET`. For browser tests, also send `x-vercel-set-bypass-cookie: true`. Once protected, `VERCEL_URL` is not publicly reachable.
- Detect: an E2E or smoke stage against a preview URL; webhook URLs pointing at previews; server code fetching `VERCEL_URL`.
- Fix: create a Protection Bypass for Automation secret and pass it from CI, e.g. via Playwright `extraHTTPHeaders`. Use relative URLs or the request origin for same-app fetches.
- Source: Protection Bypass for Automation - https://vercel.com/docs/deployment-protection/methods-to-bypass-deployment-protection/protection-bypass-automation

## GitHub Actions

### CICD-04 Service containers: Linux only, networking depends on job type, wait for readiness
- Trap: an integration or E2E job "uses Postgres" with no `services:` block; or it connects to `postgres` from a job running on the runner; or it starts tests before the database accepts connections.
- Reality: service containers need a Linux runner (Ubuntu on GitHub-hosted). A job running in a container reaches the service by its label as hostname. A job running directly on the runner uses `localhost` and must map ports (e.g. `5432:5432`). GitHub's Postgres example adds `--health-cmd pg_isready` health options so the job waits for readiness.
- Detect: DB-backed tests with no service container; macOS or Windows runners with services; host/port mismatch; no health options.
- Fix: declare the service with health options, map ports for runner jobs, and point the connection string at the right host.
- Source: Creating PostgreSQL service containers - https://docs.github.com/en/actions/tutorials/use-containerized-services/create-postgresql-service-containers

### CICD-05 Secrets are missing for fork PRs and reusable workflows
- Trap: every pull request runs the full pipeline, deploy previews and secret-backed tests included; or a reusable workflow uses the caller's secrets.
- Reality: apart from `GITHUB_TOKEN`, secrets are not passed to workflows triggered from a forked repository. Secrets are also not passed to reusable workflows automatically.
- Detect: an open-source or contributor workflow that needs secrets on PRs; `workflow_call` jobs reading secrets they were never given.
- Fix: skip secret-dependent jobs for forks. Pass secrets explicitly (`secrets:` or `secrets: inherit`) to reusable workflows.
- Source: Using secrets in GitHub Actions - https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
