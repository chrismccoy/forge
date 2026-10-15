# GitHub Security and AI Features

GitHub-hosted security: secret scanning with push protection, CodeQL code scanning, Copilot Autofix, dependency review, and AI-generated PRs. Local signing, credentials, and gitleaks live in `security.md`.

## Secret Scanning and Push Protection

Enable: Settings → Code security → Secret scanning → Enable, then enable Push protection.

Detects AWS/Azure/GCP credentials, GitHub tokens, database connection strings, API keys (OpenAI, Anthropic, Stripe, and others), private keys, OAuth tokens, and custom regex patterns. AI-based detection adds generic passwords.

**Blocked push looks like:**

```text
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Push cannot contain secrets
remote:   -- AWS Access Key
remote:     locations:
remote:       - config.py:12
 ! [remote rejected] main -> main (push declined due to repository rule violations)
```

**Fix:** The secret is in a local commit, so editing the file alone is not enough.

```bash
# Move secret to environment
#   config.py: aws_key = os.environ.get("AWS_ACCESS_KEY")
echo ".env" >> .gitignore

# Secret only in the last unpushed commit: stage only the fixed files
git add config.py .gitignore
git commit --amend --no-edit

# Secret in an earlier unpushed commit: the user runs `git rebase -i origin/main`
# and marks that commit "edit" (interactive; opens an editor)
```

Bypass ("false positive" / "used in tests") requires justification and is audited. If the secret is real, rotate it regardless. See incident response in `security.md`.

## CodeQL Code Scanning

Quick start: Settings → Code security → Code scanning → Default setup. Advanced setup workflow:

```yaml
# .github/workflows/codeql.yml
name: "CodeQL"

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1'   # weekly

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
      actions: read        # needed on private repos
    strategy:
      fail-fast: false
      matrix:
        include:
          - language: javascript-typescript
            build-mode: none
          - language: python
            build-mode: none
          - language: java-kotlin
            build-mode: autobuild
    steps:
      - uses: actions/checkout@v7   # current majors: github-actions.md
      - uses: github/codeql-action/init@v4
        with:
          languages: ${{ matrix.language }}
          build-mode: ${{ matrix.build-mode }}
          queries: security-and-quality
      - uses: github/codeql-action/analyze@v4
        with:
          category: "/language:${{ matrix.language }}"
```

Interpreted languages use `build-mode: none`. Compiled languages use `autobuild` or `manual`.

Finds SQL injection, XSS, path traversal, command injection, insecure deserialization, auth bypass, hardcoded credentials.

## Copilot Autofix

Generates fix suggestions for CodeQL alerts on PRs and in the Security tab. Review and test before applying.

```python
# Flagged: SQL injection
query = f"SELECT * FROM users WHERE id = {user_id}"
return db.execute(query)

# Autofix suggestion: parameterized query
query = "SELECT * FROM users WHERE id = ?"
return db.execute(query, (user_id,))
```

## Dependency Review

Blocks PRs that add vulnerable or disallowed dependencies.

```yaml
# .github/workflows/dependency-review.yml
name: Dependency Review
on: [pull_request]
permissions:
  contents: read
jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7   # current majors: github-actions.md
      - uses: actions/dependency-review-action@v5
        with:
          fail-on-severity: high
          fail-on-scopes: runtime
```

Pair with Dependabot (security updates + grouped version updates).

## AI-Generated PRs (Copilot Coding Agent)

Assign an issue to Copilot; it works in a branch and opens a PR for review. Rules:

- Treat AI-authored PRs like external contributions. Require human review before merge.
- Workflows on Copilot-authored PRs need approval to run, like fork PRs.
- Keep branch protection and required checks on; do not exempt bots.

## Recommended Baseline

1. Secret scanning + push protection on.
2. CodeQL (default setup or workflow above) for all project languages.
3. Review Autofix suggestions weekly; test before merge.
4. Dependency review on PRs; Dependabot on.
5. Human review for all AI-generated code.

## Resources

- [Secret scanning](https://docs.github.com/en/code-security/secret-scanning)
- [CodeQL](https://codeql.github.com/docs/)
- [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)
