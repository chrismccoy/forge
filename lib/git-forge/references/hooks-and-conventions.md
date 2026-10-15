# Git Hooks, Conventions, and Workflow Strategy

Hooks, conventional commits, branching and trunk-based development, .gitignore template. Signing, credentials, and secret tooling live in `security.md`.

## Git Hooks

### Client-Side Hooks

Hooks location: `.git/hooks/`, or a versioned directory set with `git config core.hooksPath .githooks`. With `core.hooksPath` set, Git ignores `.git/hooks` entirely.

Each hook is one file. The lint example below, the secret-scanning hook, and the gitleaks hook in `security.md` all target `pre-commit`. Combine them into one script; writing a second one replaces the first.

`.git/hooks/pre-commit` (runs before commit):

```bash
#!/bin/bash
npm run lint || exit 1
```

`.git/hooks/commit-msg` (validates the Conventional Commits header; allows scope, `!`, Git's default merge and revert messages, and fixup!/squash!/amend! commits):

```bash
#!/bin/bash
header=$(head -n1 "$1")
pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?: .+|^Merge |^Revert "|^(fixup|squash|amend)! '
if ! echo "$header" | grep -qE "$pattern"; then
    echo "Error: Commit message must match '<type>(<scope>): <subject>'"
    exit 1
fi
```

Other client-side hooks:
- `prepare-commit-msg`: Edit commit message before editor opens
- `post-commit`: Run after commit
- `pre-push`: Run before push
- `post-checkout`: Run after checkout
- `post-merge`: Run after merge

```bash
# Make hook executable
chmod +x .git/hooks/pre-commit
```

### Server-Side Hooks

- `pre-receive`: Run before refs are updated
- `update`: Run for each branch being updated
- `post-receive`: Run after refs are updated

Example `pre-receive` that rejects force pushes:

```bash
#!/bin/bash
zero=$(git hash-object --stdin </dev/null | tr '0-9a-f' '0')   # all-zero ID; works for SHA-1 and SHA-256
while read oldrev newrev refname; do
    [ "$oldrev" = "$zero" ] && continue   # new branch
    [ "$newrev" = "$zero" ] && continue   # branch deletion
    if ! git merge-base --is-ancestor "$oldrev" "$newrev"; then
        echo "Error: Force push to $refname rejected"
        exit 1
    fi
done
```

## Secret-Scanning Hook

Prefer gitleaks (see `security.md`). Minimal fallback without tools:

```bash
#!/bin/bash
if git diff --cached -U0 | grep '^+' | grep -v '^+++ ' | grep -iE 'password|secret|api_key' ; then   # added lines only, skips +++ headers
    echo "Potential secret detected!"
    exit 1
fi
```

## Commit Messages (Conventional Commits)

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance
- `perf`: Performance improvement
- `build`: Build system or dependencies
- `ci`: CI configuration
- `revert`: Revert a previous commit

Append `!` after type/scope (`feat(api)!: ...`) for breaking changes.

**Example:**

```text
feat(auth): add OAuth2 authentication

Implement OAuth2 flow for Google and GitHub providers.
Includes token refresh and revocation.

Closes #123
```

## Branching Best Practices

1. Keep branches short-lived (< 1 day ideal; see Trunk-Based Development)
2. Use descriptive names: `feature/user-auth`, `fix/header-crash`
3. One purpose per branch
4. Rebase an unpushed or unshared branch onto `main` before merging; never rebase a branch others have pulled (see `merging-rebasing.md`)
5. Delete merged branches

## Branch Strategies

Follow the project's existing convention. Choose for new projects:

- **Git Flow:** `main` (production), `develop` (integration), `feature/*`, `release/*`, `hotfix/*`. Merges with `--no-ff` preserve branch history.
- **GitHub Flow:** `main` always deployable; short-lived `feature/*` branches; PR, review, merge.
- **Trunk-Based Development:** see below.
- **GitLab Flow:** environment branches (`production`, `staging`) downstream of `main`; deploy from environment branches.

## Trunk-Based Development

Branches live hours to one day. `main` stays deployable. Feature flags hide unfinished work.

```bash
git switch main && git pull origin main
git switch -c task/add-login-button

git add src/components/LoginButton.tsx
git commit -m "feat: add login button component"
git push -u origin task/add-login-button
gh pr create --draft --title "Add login button" --body "Implements login UI"

# More small commits, then
gh pr ready
gh pr merge --squash --delete-branch
```

Keep commits to roughly 1–3 files, 50–200 lines. One logical change each. Push every few hours. Small PRs merge faster with fewer conflicts.

## Workflow Best Practices

1. Commit often (small, logical chunks)
2. Pull before push (stay up to date)
3. Review before commit (`git diff --staged`)
4. Write meaningful messages
5. Test before commit
6. Never commit secrets (use `.gitignore`, environment variables)

## .gitignore Template

For the secrets list (keys, certificates, cloud credentials), see `security.md`.

```gitignore
# Environment files
.env
.env.*
*.env
!.env.example

# Dependencies
node_modules/
vendor/
venv/

# Build outputs
dist/
build/
*.exe
*.dll
*.so

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
```
