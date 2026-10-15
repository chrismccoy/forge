# GitHub Actions: 2025–2026 Changes and Best Practices

Runner choices, immutable releases, Node24 migration, action versions, environments, action pinning, artifacts, image retirements, and self-hosted runner networking. Generic CI templates for other hosts live in `platform-workflows.md`.

## Runner Selection

| Workload | Runner |
|----------|--------|
| Triage, labels, PR comments, tagging, notifications | 1 vCPU Linux runner `ubuntu-slim` (GA January 2026; 1 vCPU, 5 GB RAM, 15-minute job limit) |
| Builds, tests, CI pipelines | `ubuntu-latest` / `windows-latest` / `macos-latest` |
| Heavy builds | Larger runners (org setting) |

```yaml
jobs:
  triage:
    runs-on: ubuntu-slim
    timeout-minutes: 10        # stay under the 15-minute cap
    permissions:
      issues: write
    steps:
      - run: gh issue edit ${{ github.event.issue.number }} --add-label "needs-review"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GH_REPO: ${{ github.repository }}   # no checkout, so gh needs the repo explicitly
```


## Immutable Releases

Repository or org setting (Settings → Releases → Enable release immutability). Once published, the release's assets cannot be changed or deleted, and its tag cannot be moved or deleted. Supports supply-chain integrity and audit.

Upload all assets before publishing, because a published immutable release cannot be edited:

```bash
gh release create v1.0.0 --draft --title "v1.0.0" --notes-file CHANGELOG.md
gh release upload v1.0.0 dist/*.zip
gh release edit v1.0.0 --draft=false
```

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v7
      - run: npm ci && npm run build
      - run: |
          gh release create "$GITHUB_REF_NAME" --draft --title "$GITHUB_REF_NAME" --notes-file CHANGELOG.md
          gh release upload "$GITHUB_REF_NAME" dist/*.zip
          gh release edit "$GITHUB_REF_NAME" --draft=false
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Node24 Migration

Timeline (GitHub changelog):
- Runners switched JavaScript actions to Node24 by default on June 16, 2026.
- Node20 was removed from runners on September 23, 2026. Actions still declaring `node20` no longer run.
- Before the switch, `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` forced Node24 for testing.
- Node24 does not support macOS 13.4 and lower, or self-hosted ARM32 runners.

Upgrade every action to a major release that declares `using: node24`. As of October 2026:

| Action | Current major |
|--------|---------------|
| `actions/checkout` | v7 |
| `actions/setup-node` | v7 |
| `actions/upload-artifact` | v7 |
| `actions/download-artifact` | v8 |
| `github/codeql-action/*` | v4 |
| `actions/dependency-review-action` | v5 |

Check each action's latest release before pinning (`gh release view -R actions/checkout`), because majors move.

```yaml
- uses: actions/setup-node@v7
  with:
    node-version: '24'
```

Custom JavaScript actions (`action.yml`):

```yaml
runs:
  using: 'node24'
  main: 'index.js'
```

```bash
npm install @actions/core@latest @actions/github@latest
nvm install 24 && nvm use 24 && npm test
```

## Deployment Environments

Configure under Settings → Environments: required reviewers, wait timer, allowed deployment branches.

Plan limits (check current docs before relying on them):
- **GitHub Free:** environments on public repos only.
- **Pro / Team:** environments on private repos, but required reviewers and wait timers work only on public repos.
- **Enterprise:** required reviewers and wait timers on private repos too.

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.example.com
    steps:
      - run: echo "Deploying to ${{ vars.DEPLOY_URL }}"
```

## Action Pinning and Allowed-Actions Policy

Tags are mutable; a compromised tag can run new code in the workflow. Pin third-party actions to a full commit SHA.

```yaml
- uses: actions/checkout@<40-char-commit-sha>  # v7.0.1
```

```bash
# Resolve a tag to its commit SHA
gh api repos/actions/checkout/commits/v7.0.1 --jq '.sha'
```

Org/repo policy (Settings → Actions → General) can allow only selected actions, block specific actions, and require SHA pinning (August 2025).

## Artifacts

`actions/upload-artifact` and `download-artifact` v1–v3 are retired (v4 moved to a new backend). Use a current Node24 major:

```yaml
- uses: actions/upload-artifact@v7
  with:
    name: build-artifacts
    path: dist/
    retention-days: 30
```

Since v4, artifact names must be unique within a run.

## Runner Image Retirements

| Image | Retired | Replace with |
|-------|---------|--------------|
| `ubuntu-20.04` | April 2025 | `ubuntu-24.04` / `ubuntu-latest` |
| `windows-2019` | June 30, 2025 | `windows-2022` / `windows-latest` |
| `macos-13` (incl. `-large`, `-xlarge`) | December 4, 2025 | arm64 `macos-latest`, or `macos-15-intel` for x86_64 |

## Self-Hosted Runner Networking

```bash
curl -s https://api.github.com/meta | jq '.domains.actions_inbound'   # full_domains, wildcard_domains
curl -s https://api.github.com/meta | jq '.actions'                   # IP ranges (thousands; prefer domains)
```

Allow these in firewalls.

## Best Practices

1. Smallest runner that fits the job; set `timeout-minutes`.
2. Least-privilege `permissions:` per job.
3. SHA-pin third-party actions.
4. Immutable releases for production tags.
5. Environments with required reviewers for deploys.
6. Node24 action majors everywhere (see table above).

## Resources

- [1 vCPU Linux runner GA](https://github.blog/changelog/2026-01-22-1-vcpu-linux-runner-now-generally-available-in-github-actions/)
- [Actions policy: blocking and SHA pinning](https://github.blog/changelog/2025-08-15-github-actions-policy-now-supports-blocking-and-sha-pinning-actions/)
- [Node 20 deprecation](https://github.blog/changelog/2026-09-23-deprecation-of-node-20-on-github-actions-runners/)
- [macOS 13 image retirement](https://github.blog/changelog/2025-09-19-github-actions-macos-13-runner-image-is-closing-down/)
