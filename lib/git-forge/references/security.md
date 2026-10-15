# Git Security: Signing, Credentials, Secrets, Enforcement

Signed commits (GPG/SSH), credential management, secret scanning tools, enforcement (branch protection, server hooks), hardened config, audit trail, checklist, and incident response. GitHub-hosted scanning (push protection, CodeQL, Copilot Autofix, dependency review) lives in `github-security.md`.

## Zero-Trust Model

Authenticate every identity, sign every commit, log every operation, assume breach.

1. **Never trust, always verify:** require signed commits, verify in CI.
2. **Least privilege:** no direct pushes to protected branches.
3. **Continuous monitoring:** audit logs, secret scanning on every push.
4. **Defense in depth:** local hooks + CI checks + server enforcement.

Prefer the host's "Require signed commits" rule. Hosted CI runners have no GPG keyring or allowed-signers file, so `git verify-commit` fails there. To check in CI anyway, use GitHub's own verification:

```yaml
- name: Verify all PR commits are signed
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    unsigned=$(gh api "repos/$GITHUB_REPOSITORY/pulls/${{ github.event.pull_request.number }}/commits" \
      --paginate --jq '.[] | select(.commit.verification.verified | not) | .sha')
    if [ -n "$unsigned" ]; then
      echo "Unsigned commits:"; echo "$unsigned"; exit 1
    fi
```

Branch protection for zero-trust (conceptual; configure in host UI or API):

```yaml
main:
  required_pull_request_reviews: true
  dismiss_stale_reviews: true
  require_code_owner_reviews: true
  required_approving_review_count: 2
  require_signed_commits: true
  enforce_admins: true
```

## Signed Commits

### SSH Signing (simplest; reuses SSH keys)

```bash
ls -la ~/.ssh/id_ed25519.pub
# If missing, hand to the user (prompts for a passphrase):
#   ssh-keygen -t ed25519 -C "your.email@example.com"

git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# Upload: GitHub Settings → SSH and GPG keys → New SSH key → Key type: Signing Key
cat ~/.ssh/id_ed25519.pub

# Local verification needs an allowed signers file
echo "your.email@example.com $(cat ~/.ssh/id_ed25519.pub)" >> ~/.ssh/allowed_signers   # append; keep other signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
git verify-commit HEAD
```

### GPG Signing

```bash
gpg --full-generate-key                      # interactive: hand to the user. RSA 4096 or ed25519, set an expiry
gpg --list-secret-keys --keyid-format=long

git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
git config --global tag.gpgsign true

gpg --armor --export <KEY_ID>                # paste into GitHub/GitLab/Bitbucket

git commit -S -m "feat: add authentication"
git log --show-signature
git verify-commit HEAD
git verify-tag v1.0.0
```

**GPG troubleshooting:**

```bash
export GPG_TTY=$(tty)
echo 'export GPG_TTY=$(tty)' >> ~/.bashrc

# Passphrase cache: 1 hour idle, 8 hours max (defaults are 10 min / 2 h). Ask before raising further
echo 'default-cache-ttl 3600' >> ~/.gnupg/gpg-agent.conf
echo 'max-cache-ttl 28800' >> ~/.gnupg/gpg-agent.conf
gpg-connect-agent reloadagent /bye

echo "test" | gpg --clearsign
```

### Re-sign Existing Commits

Rewrites history. Follow `dangerous-operations.md` safety protocol first.

```bash
git log --format='%h %G? %s' | awk '$2=="N"'   # list unsigned commits
git rebase -f -S --rebase-merges HEAD~10   # -f recreates every commit; -S signs; keeps merge commits
git push --force-with-lease --force-if-includes
```

## Credential Management

### SSH Keys

```bash
# Interactive (passphrase prompts): hand these to the user
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/id_ed25519_work
# Prefer ed25519. Use RSA 4096 only where ed25519 is unsupported. Never DSA.
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_work

# First connection asks to confirm the host key: hand to the user
ssh -T git@github.com
ssh -T git@ssh.dev.azure.com
```

Per-host keys in `~/.ssh/config`:

```text
Host github.com
  IdentityFile ~/.ssh/id_ed25519_github

Host gitlab.com
  IdentityFile ~/.ssh/id_ed25519_gitlab
```

### HTTPS Credential Helpers

Use an OS credential store. Avoid `credential.helper store` (plaintext on disk). **Pick one line**: each `credential.helper` set overwrites the previous one.

```bash
git config --global credential.helper manager       # Git Credential Manager (cross-platform)
git config --global credential.helper wincred       # Windows (legacy)
git config --global credential.helper osxkeychain   # macOS
# Linux (libsecret). Paths are distro-specific: Debian/Ubuntu ship source under
# /usr/share/doc/git/contrib/credential/libsecret (build: sudo make -C <that dir>);
# Fedora/Arch ship a binary such as /usr/libexec/git-core/git-credential-libsecret
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret   # Debian/Ubuntu after build
git config --global credential.helper 'cache --timeout=3600'   # temporary, in memory
```

### Personal Access Tokens

- GitHub: Settings → Developer settings → Personal access tokens → Fine-grained tokens.
- Set an expiry; grant minimum scopes; rotate periodically.
- Never embed tokens in remote URLs (they land in `.git/config` and shell history). Use `gh auth login` or a credential helper.

## Secret Prevention (Local)

### Gitleaks

```bash
brew install gitleaks         # macOS
choco install gitleaks        # Windows
# Linux: download a release binary from https://github.com/gitleaks/gitleaks/releases

# v8.19+ syntax (detect/protect are deprecated)
gitleaks git                                      # scan repo history
gitleaks git --pre-commit --staged                # scan staged changes
gitleaks dir ./src                                # scan files in a directory
gitleaks git --report-format json --report-path gitleaks-report.json
gitleaks git --exit-code 1                        # CI gate
```

Pre-commit hook (`.git/hooks/pre-commit`, then `chmod +x`). If a pre-commit hook already exists, add these lines to it (see `hooks-and-conventions.md`):

```bash
#!/bin/bash
if ! gitleaks git --pre-commit --redact --staged --verbose; then
    echo "Gitleaks detected secrets. Commit blocked."
    exit 1
fi
```

### git-secrets (AWS-focused)

```bash
brew install git-secrets
git secrets --install
git secrets --register-aws
git secrets --add 'password\s*=\s*[^\s]+'
git secrets --add 'api[_-]?key\s*=\s*[^\s]+'
git secrets --scan
git secrets --scan-history
```

### .gitignore for Secrets

```gitignore
.env
.env.*
*.pem
*.key
*.p12
*.pfx
*_rsa
*_dsa
*_ecdsa
*_ed25519
credentials.json
secrets.yaml
config/secrets.yml
.aws/
.azure/
.gcloud/
gcloud-service-key.json
```

## Enforcement

### Branch Protection

- **GitHub:** Settings → Branches (or Rulesets) → Require signed commits, linear history, status checks.
- **GitLab:** Settings → Repository → Protected branches; push rules → reject unsigned commits.
- **Azure DevOps:** Branch Policies → require reviewers, build validation.

### Server-Side pre-receive Hook

The server needs the public keys to verify: a GPG keyring with contributors' keys, or `gpg.ssh.allowedSignersFile` for SSH signatures. Without them every commit fails verification.

```bash
#!/bin/bash
zero_commit=$(git hash-object --stdin </dev/null | tr '0-9a-f' '0')   # all-zero ID; works for SHA-1 and SHA-256

while read oldrev newrev refname; do
  [ "$newrev" = "$zero_commit" ] && continue        # branch deletion
  if [ "$oldrev" = "$zero_commit" ]; then
    range="$newrev --not --all"                     # new branch: only new commits
  else
    range="$oldrev..$newrev"
  fi
  for commit in $(git rev-list $range); do
    if ! git verify-commit "$commit" 2>/dev/null; then
      echo "Error: Commit $commit is not signed"
      echo "Configure with: git config commit.gpgsign true"
      exit 1
    fi
  done
done
exit 0
```

## Hardened Git Config

```bash
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global transfer.fsckObjects true   # covers fetch.fsckObjects and receive.fsckObjects
```

## Audit Trail

```bash
git config --global alias.audit 'log --all --pretty="%H|%an|%ae|%ad|%s|%G?|%GK" --date=iso'
git audit > git-audit.log

git log --show-signature -10
git log --show-signature main..HEAD
git log --since="24 hours ago" --pretty=format:"%an <%ae> %s"
```

`%G?` prints signature status: `G` good, `B` bad, `U` good with unknown validity, `X` good but expired signature, `Y` good but made by an expired key, `R` good but made by a revoked key, `E` cannot be checked (e.g. missing key), `N` no signature.

## Security Checklist

**Repository:** branch protection; signed commits required; secret scanning + push protection; CodeQL or equivalent; Dependabot/Renovate; 2FA for contributors.

**Workstation:** SSH or GPG signing; OS credential manager (never plaintext); gitleaks pre-commit hook; secrets in `.gitignore`; `fsckObjects` enabled; passphrase on SSH keys.

**Workflow:** never commit secrets; review `git diff --staged` before commit; verify signatures on merge; rotate credentials; use environment variables or a secret manager.

## Incident Response: Secret Leaked

1. **Rotate the credential immediately.** Rewriting history does not un-leak a pushed secret; clones, forks, and caches keep it.
2. If not pushed: amend or reset the commit and remove the secret.

   ```bash
   git reset HEAD~1
   git rm --cached config/secrets.yml          # untrack it if it was tracked before
   echo "config/secrets.yml" >> .gitignore     # then ignore it
   # move secret to env var, then stage only the files you changed
   git add .gitignore <changed-files> && git commit -m "chore: move config to environment"
   ```

3. If pushed and the history rewrite is approved, follow the Filter-Repo procedure in `dangerous-operations.md` exactly (confirm, freeze pushes, mirror backup, fresh clone, rewrite, `ls-remote` check, push without fetching). Use `--path config/secrets.yml --invert-paths`. The mirror backup still contains the secret: store it securely and delete it when done.
4. Tell collaborators to re-clone. On GitHub, contact support to purge cached views of the commit.
5. Enable push protection to block repeats.

## Resources

- [Signing your work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [git-filter-repo](https://github.com/newren/git-filter-repo)
