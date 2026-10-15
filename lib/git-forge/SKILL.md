# Git Forge - Complete Git Expert

Comprehensive Git procedure covering basic to advanced operations, with mandatory safety guardrails for destructive commands and platform-specific workflows.

The files named below live in `${CLAUDE_PLUGIN_ROOT}/lib/git-forge/`.

## TL;DR Safety First

Before ANY destructive operation:

```bash
# ALWAYS check status first
git status
git log --oneline -10

# Back up what the operation can lose:
git branch backup-$(date +%Y%m%d-%H%M%S)   # commits (reset, rebase, amend)
# filter-repo: git clone --mirror <url> (filter-repo rewrites backup branches too)
# git clean: copy the untracked files first; stash drop/clear: git stash export --to-ref refs/stashes/backup (2.51+)

# Remember: git reflog is the safety net
# (reachable entries 90 days; unreachable, e.g. after reset --hard, 30 days)
git reflog
```

**Commit Preference Check.** Ask once per session, only before the first task that would change the repository (commit, stage, push, rewrite). Skip it for read-only questions and explanations.

Ask with `AskUserQuestion` - question: "How much should I do in this repository?", header: "Commits":

1. **Commit for me** - create commits automatically with appropriate messages
2. **Stage only** - stage changes; the user handles commits manually
3. **Guidance only** - no automatic operations; give the commands to run

Respect this choice throughout the session.

## Scope

All Git and Git-hosting work, from `git init` to history rewrites, plus GitHub Actions and GitHub security features. Load the matching reference before running a category of commands.

## Core Principles

### 1. Safety Guardrails for Destructive Operations

Before ANY destructive operation (`reset --hard`, force push, `filter-repo`, etc.):

1. Always warn the user explicitly
2. Explain the risks clearly
3. Ask for confirmation
4. Create a backup first: a backup branch, or a `git clone --mirror` for filter-repo
5. Provide recovery instructions

Get confirmation in the conversation, never with interactive `read -p` scripts. See `references/dangerous-operations.md` for the full safety protocols.

### 2. Non-Interactive Execution

The Bash tool has no TTY. Commands that open an editor or prompt hang or fail. Use non-interactive forms:

- `git commit -m "..."`, or `--no-edit` when amending; `GIT_EDITOR=true` for merges and other commands that open an editor
- `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <target>^` to apply fixup!/squash! commits (`--root` instead of `<target>^` when the target is the root commit)
- `GIT_EDITOR=true git merge|rebase|cherry-pick|revert --continue`; `git tag -a <name> -m "..."`
- `gh pr create --fill` (or `--title`/`--body`), `gh pr merge <n> --squash|--merge|--rebase`, `glab mr create --fill --yes`, `glab mr merge <id> --yes`
- Signing and auth can prompt (GPG pinentry, SSH key passphrase, HTTPS username, first-connection host key). Run network commands with `GIT_TERMINAL_PROMPT=0` to fail fast instead of hanging. If a signed commit or push fails on a prompt, hand `gh auth login`, `ssh-add`, a first `ssh -T git@<host>`, or `echo test | gpg --clearsign` (caches the passphrase) to the user, then retry
- Hand truly interactive work to the user: `git rebase -i` with manual edits, `git add -p`, `git clean -i`, `git mergetool`, `ssh-keygen`, `gpg --full-generate-key`

### 3. Platform Awareness

Git behavior differs across platforms and hosting providers:

- **Windows (Git Bash/PowerShell):** Line endings (`core.autocrlf`), path separators, case sensitivity, Windows Credential Manager
- **Linux/macOS:** Case-sensitive filesystems, SSH key management, permissions
- **Hosting platforms:** GitHub (PRs, Actions, `gh` CLI), Azure DevOps (PRs, Pipelines, policies), Bitbucket (PRs, Pipelines), GitLab (MRs, CI/CD)

See `references/platform-workflows.md` for hosting-specific commands and `references/cross-platform.md` for Windows/Linux/macOS handling.

## Reference Map

This SKILL.md is a lean orchestrator. Detailed command catalogs and procedures live in `references/`:

| Reference | Contents |
|-----------|----------|
| `references/basic-operations.md` | Init, clone, config, basic workflow, branches, remotes, fetch/pull/push |
| `references/merging-rebasing.md` | Merge strategies, conflict resolution, rebase (interactive/onto/autosquash), cherry-pick |
| `references/advanced-commands.md` | Stash (incl. Git 2.51+ export/import via refs), revert, reflog, bisect, clean, worktree basics, submodules, tags |
| `references/dangerous-operations.md` | Reset (hard/soft/mixed), force push, filter-repo, remote branch/tag deletion, amend pushed commits, safety protocols |
| `references/platform-workflows.md` | GitHub, Azure DevOps, Bitbucket, GitLab CLIs and CI/CD templates |
| `references/performance-large-files.md` | GC, repack, fsck, LFS, shallow clones, large-file discovery |
| `references/hooks-and-conventions.md` | Client/server hooks, conventional commits, branch strategies (Git Flow, GitHub Flow, trunk-based, GitLab Flow), .gitignore template |
| `references/security.md` | Zero-trust model, SSH/GPG signing, credential helpers, PATs, gitleaks/git-secrets, branch protection, pre-receive enforcement, audit, leaked-secret incident response |
| `references/modern-git-features.md` | Git 2.48–2.53 release highlights, reftables, sparse-checkout, partial clone, `git backfill`, path-walk, Scalar, advanced worktree patterns, Git 3.0 changes |
| `references/github-actions.md` | Runner selection (`ubuntu-slim`), immutable releases, Node24 timeline and current action majors, environments, SHA pinning, artifacts, image retirements, self-hosted runner networking (meta API) |
| `references/github-security.md` | Secret scanning push protection, CodeQL workflow, Copilot Autofix, dependency review, AI-authored PRs |
| `references/troubleshooting-recovery.md` | Detached HEAD, rejected (non-fast-forward) push, wrong-branch commit, recovery scenarios, corrupted repo, undoing a force push |
| `references/cross-platform.md` | Line endings, case sensitivity, Git Bash/MINGW path conversion, shell detection |

## Quick Command Index

| Task | Reference |
|------|-----------|
| `git init`, `git clone`, `git add`, `git commit`, `git log`, `git diff` | basic-operations |
| `git branch`, `git switch`, `git remote`, `git fetch`, `git pull`, `git push` | basic-operations |
| `git merge`, conflict markers, `git rebase -i`, `git cherry-pick` | merging-rebasing |
| `git stash`, `git revert`, `git reflog`, `git bisect`, `git clean`, `git worktree`, `git submodule`, `git tag` | advanced-commands |
| `git reset --hard`, `git push --force[-with-lease]`, `git filter-repo`, amend pushed | dangerous-operations |
| `gh pr`, `az repos pr`, `bb pr`, `glab mr`, CI/CD YAML | platform-workflows |
| `git gc`, `git repack`, `git lfs`, shallow clone | performance-large-files |
| `.git/hooks/*`, conventional commits, trunk-based development | hooks-and-conventions |
| `commit.gpgsign`, `gpg.format ssh`, `credential.helper`, `gitleaks`, leaked secret | security |
| `git refs migrate`, `git sparse-checkout`, `--filter=blob:none`, `git backfill`, `scalar`, `repack --path-walk` | modern-git-features |
| `runs-on`, `setup-node`, `upload-artifact`, `gh release`, action SHA pinning | github-actions |
| GH013 push rejection, `codeql-action`, `dependency-review-action`, Copilot Autofix | github-security |
| Detached HEAD, `! [rejected] (fetch first / non-fast-forward)`, recover branch/file/commit, corrupted repo | troubleshooting-recovery |
| `core.autocrlf`, `core.ignorecase`, `MSYS_NO_PATHCONV`, `cygpath`, `$MSYSTEM` | cross-platform |

## Success Criteria

A Git workflow using this procedure should:

1. Respect the commit preference (asked once, before the first repository change)
2. ALWAYS warn before destructive operations
3. ALWAYS back up before risky operations (backup branch; mirror clone for filter-repo)
4. ALWAYS explain recovery procedures
5. Use appropriate branch strategy for the project
6. Write meaningful commit messages
7. Keep history readable, following the project's merge convention (linear or `--no-ff`)
8. Never commit secrets or large binary files
9. Test code before committing
10. Know how to recover from any mistake
