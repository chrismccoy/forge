# Dangerous Git Operations (High Risk)

Reference for destructive Git operations that REQUIRE safety protocols and explicit user confirmation. Always back up first: a backup branch, or a mirror clone for filter-repo.

## Safety Pattern (Apply to ALL Destructive Operations)

Get confirmation **in the conversation**, not with `read -p` scripts. The Bash tool is non-interactive: `read` gets EOF, and an `exit` pasted into a user's shell closes it.

1. Run the read-only checks: `git status`, `git log --oneline -10`, and any operation-specific check below.
2. Tell the user exactly what will be lost: uncommitted changes, rewritten commits, other people's remote commits.
3. Back up what can be lost. Commits: `git branch backup-$(date +%Y%m%d-%H%M%S)`. filter-repo: a mirror clone (see below). `git clean`: copy the files `git clean -nd` lists. Stash drop/clear: `git stash export --to-ref refs/stashes/backup` (2.51+).
4. State the recovery command, e.g. `git reset --hard backup-<timestamp>`.
5. Wait for an explicit "yes" from the user before running the destructive command.

## Reset

**WARNING: reset can permanently delete changes.**

```bash
# Soft reset (keep changes staged)
git reset --soft <commit>
git reset --soft HEAD~1  # Undo last commit, keep changes staged

# Mixed reset (default - keep changes unstaged)
git reset <commit>
git reset HEAD~1  # Undo last commit, keep changes unstaged

# HARD reset (DELETE all changes - DANGEROUS!)
# ALWAYS create backup branch first!
git branch backup-$(date +%Y%m%d-%H%M%S)
git reset --hard <commit>
git reset --hard HEAD~1               # Undo last commit and DELETE all changes
git reset --hard origin/<branch>      # Reset to remote state

# Unstage files
git reset HEAD <file>
git reset -- <file>

# DESTRUCTIVE: overwrite one file with its version at <commit> (local edits to it are lost)
git restore --source=<commit> -- <file>
```

## Force Push

```bash
# DANGEROUS: Force push (overwrites remote history)
# ALWAYS ASK USER FOR CONFIRMATION FIRST
git push --force
git push -f

# SAFER: Force push with lease (fails if remote updated)
git push --force-with-lease --force-if-includes
git push --force-with-lease=<ref>:<expected-value>   # explicit lease
```

### Force Push Safety Protocol

Before ANY force push, run these read-only checks and show the result to the user:

```bash
git fetch origin
git log --oneline --decorate origin/<branch> ^<branch>   # commits that would be LOST
```

- Empty output: no remote commits will be lost.
- Any output: other people's commits will be destroyed. Integrate them first, or get explicit confirmation.

Prefer `git push --force-with-lease --force-if-includes`. A bare `--force-with-lease` is defeated when something fetches in the background (IDE, `git fetch`), because the lease then matches the new remote tip. `--force-if-includes` also requires that the remote tip is in the local branch's reflog.

## Filter-Repo (History Rewriting)

**EXTREMELY DANGEROUS: Rewrites entire repository history.** It changes every commit hash, breaks every existing clone, and cannot be undone after the force push.

### 1. Safety Protocol (do this first)

1. Tell the user the risks above and get explicit confirmation in the conversation.
2. Notify all collaborators and ask them to stop pushing until told otherwise.
3. Make a full backup: `git clone --mirror <repo-url> backup-$(date +%Y%m%d-%H%M%S).git`. Do not use a backup branch, because filter-repo rewrites every branch, backups included. If the purge is for a secret, the backup still contains it: store it securely and delete it when no longer needed.
4. Run filter-repo in a **fresh clone**: `git clone <repo-url> repo-rewrite && cd repo-rewrite`. filter-repo refuses to run in a non-fresh clone. Do not add `--force` to get past that check; it protects unpushed work.

### 2. Rewrite

```bash
# Install git-filter-repo (not built-in)
# pip install git-filter-repo

# Remove file from all history. Pass every historical name of a renamed file
# (list them: git log --all --follow --name-only --format= -- <file> | sort -u)
git filter-repo --path <file> --invert-paths

# Remove directory from all history
git filter-repo --path <directory> --invert-paths

# Change author info
git filter-repo --name-callback 'return name.replace(b"Old Name", b"New Name")'
git filter-repo --email-callback 'return email.replace(b"old@email.com", b"new@email.com")'

# Remove large files
git filter-repo --strip-blobs-bigger-than 10M
```

### 3. Push

filter-repo removes the `origin` remote by design. Do **not** fetch after the rewrite. Fetching pulls the purged objects back, and it refreshes the lease so `--force-with-lease` always passes.

```bash
git remote add origin <repo-url>
git ls-remote origin            # compare with the backup: confirm nobody pushed during the freeze
git push --force --all
git push --force --tags
```

Then have collaborators re-clone. Lift the push freeze after that.

## Delete Remote Branches and Tags

**DANGER:** unmerged commits on a deleted remote branch survive only in other clones. Tags others fetched will reappear or diverge.

```bash
git log --oneline origin/<branch> --not origin/main   # commits that only this branch has
git push origin --delete <branch>
git push origin --delete refs/tags/<tag>
```

Recovery: re-push from any clone that still has it (`git push origin <sha>:refs/heads/<branch>`).

## Amend Pushed Commits

**DANGER: Changing pushed commits requires force push.**

```bash
# Amend last commit with a new message (bare --amend opens an editor)
git commit --amend -m "new message"

# Amend without changing message
git commit --amend --no-edit

# Change author of last commit
git commit --amend --author="Name <email>" --no-edit

# Force push required if already pushed
git push --force-with-lease --force-if-includes
```

## Rewrite Multiple Commits

**DANGER: Interactive rebase on pushed commits.**

```bash
# Interactive rebase opens an editor: hand it to the user
git rebase -i HEAD~5

# Change author of every commit after <base> (non-interactive).
# Add --rebase-merges if the range has merge commits, or they are flattened
git rebase <base> --exec 'git commit --amend --no-edit --author="Name <email>"'

# Change author of one older commit: user runs `git rebase -i <commit>^`,
# marks it "edit", then:
git commit --amend --author="Name <email>" --no-edit
git rebase --continue

# Force push required
git push --force-with-lease --force-if-includes
```
