# Platform-Specific Git Workflows

Reference patterns for GitHub, Azure DevOps, Bitbucket, and GitLab.

## GitHub

### Pull Requests with GitHub CLI

```bash
# Install GitHub CLI from https://cli.github.com/

# Create PR (always pass flags: bare `gh pr create` prompts interactively)
gh pr create --fill                                  # title/body from commits
gh pr create --title "Title" --body "Description"
gh pr create --base main --head feature-branch --fill

# List PRs
gh pr list

# View PR
gh pr view
gh pr view <number>

# Check out PR locally
gh pr checkout <number>

# Review PR (pass an action flag; --request-changes/--comment need --body)
gh pr review <number> --approve
gh pr review <number> --request-changes --body "Reason"
gh pr review <number> --comment --body "Comment"

# Merge PR (pass a merge method; bare `gh pr merge` prompts)
gh pr merge <number> --squash --delete-branch
gh pr merge --rebase
gh pr merge --merge

# Close PR
gh pr close <number>
```

### GitHub Actions

For runners, Node24, immutable releases, SHA pinning, and environments, see `github-actions.md`. For CodeQL and secret scanning, see `github-security.md`.

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7   # current majors: github-actions.md
      - name: Run tests
        run: npm test
```

## Azure DevOps

### Pull Requests

```bash
# Install Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
az extension add --name azure-devops
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>

# Create PR
az repos pr create --title "Title" --description "Description"
az repos pr create --source-branch feature --target-branch main

# List PRs
az repos pr list

# View PR
az repos pr show --id <id>

# Complete PR
az repos pr update --id <id> --status completed

# Branch policies
az repos policy list
az repos policy create --config policy.json
```

### Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  - main
pool:
  vmImage: 'ubuntu-latest'
steps:
  - script: npm test
    displayName: 'Run tests'
```

## Bitbucket

### Pull Requests

Bitbucket has no official CLI. `bb` below is a third-party tool. Otherwise use the web UI or the REST API (`/2.0/repositories/{workspace}/{repo}/pullrequests`).

```bash
# Create PR (third-party bb CLI; may prompt, so hand interactive use to the user)
bb pr create

# Review PR
bb pr list
bb pr view <id>

# Merge PR
bb pr merge <id>
```

### Bitbucket Pipelines

```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - step:
        script:
          - npm test
```

## GitLab

### Merge Requests

```bash
# Install GitLab CLI (glab) from
# https://gitlab.com/gitlab-org/cli

# Create MR (always pass flags: bare `glab mr create` prompts)
glab mr create --fill --yes
glab mr create --title "Title" --description "Description" --yes

# List MRs
glab mr list

# View MR
glab mr view <id>

# Merge MR
glab mr merge <id> --yes   # skip the confirmation prompt

# Close MR
glab mr close <id>
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
test:
  stage: test
  script:
    - npm test
```
