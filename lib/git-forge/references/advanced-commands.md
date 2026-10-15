# Advanced Git Commands

Stash, revert, reflog, bisect, clean, worktrees, submodules, and tags.

## Stash

```bash
# Stash changes
git stash
git stash push -m "message"

# Stash including untracked files
git stash -u
git stash --include-untracked

# Stash including ignored files
git stash -a
git stash --all

# List stashes
git stash list

# Show stash contents
git stash show
git stash show -p  # With diff
git stash show stash@{2}

# Apply stash (keep in stash list)
git stash apply
git stash apply stash@{2}

# Pop stash (apply and remove)
git stash pop
git stash pop stash@{2}

# DESTRUCTIVE: drop stash (recoverable only via `git fsck --unreachable` while not yet pruned)
git stash list                 # confirm which entry first
git stash drop stash@{2}

# DESTRUCTIVE: clear ALL stashes. Confirm with the user first
git stash clear

# Create branch from stash
git stash branch <branch-name>
git stash branch <branch-name> stash@{1}
```

### Git 2.51+: Import/Export Stashes

Export stashes as a commit chain under a ref, then push and fetch that ref like a branch:

```bash
# Export all stashes (or name specific ones) to a ref
git stash export --to-ref refs/stashes/wip
git stash export --to-ref refs/stashes/wip stash@{0}
git stash export --print          # print the commit ID instead

# Share
git push origin refs/stashes/wip

# On the other machine
git fetch origin refs/stashes/wip:refs/stashes/wip
git stash import refs/stashes/wip
```

## Revert

```bash
# Revert commit (creates new commit that undoes changes)
# Safer than reset for shared branches. --no-edit skips the editor
git revert --no-edit <commit>

# Revert without creating commit
git revert -n <commit>
git revert --no-commit <commit>

# Revert merge commit
git revert -m 1 <merge-commit>  # Keep first parent
git revert -m 2 <merge-commit>  # Keep second parent

# Revert multiple commits
git revert <commit1> <commit2>
git revert <commit1>^..<commit5>   # commit1 through commit5 (A..B would exclude A)

# Continue after resolving conflicts
GIT_EDITOR=true git revert --continue

# Abort revert
git revert --abort
```

## Reflog (Recovery)

**reflog is the safety net.** Entries for commits still reachable expire after 90 days (`gc.reflogExpire`). Entries for unreachable commits, such as those dropped by `reset --hard`, expire after 30 days (`gc.reflogExpireUnreachable`).

```bash
# View reflog
git reflog
git reflog show
git reflog show <branch>

# More detailed reflog
git log -g          # Reflog as log
git log -g --all

# Find lost commits
git reflog --all
git fsck --lost-found

# Recover deleted branch
git reflog  # Find commit where branch existed
git branch <branch-name> <commit-hash>

# Recover from hard reset (non-destructive; see troubleshooting-recovery.md)
git reflog  # Find commit before reset
git branch recovered <commit-hash>

# Recover deleted commits
git cherry-pick <commit-hash>

# Reflog expiration (change retention)
git config gc.reflogExpire "90 days"
git config gc.reflogExpireUnreachable "30 days"
```

## Bisect (Find Bad Commits)

```bash
# Start bisect
git bisect start

# Mark current commit as bad
git bisect bad

# Mark known good commit
git bisect good <commit>

# Test each commit, then mark as good or bad
git bisect good   # Current commit is good
git bisect bad    # Current commit is bad

# Automate with test script
git bisect run <test-script>

# Bisect shows the first bad commit

# Finish bisect
git bisect reset

# Skip commit if unable to test
git bisect skip
```

## Clean

**WARNING: clean permanently deletes untracked files.**

```bash
# Show what would be deleted (dry run - ALWAYS do this first!)
git clean -n
git clean --dry-run

# DESTRUCTIVE: delete untracked files (unrecoverable). Preview with -n and confirm first
git clean -f

# Preview first (always)
git clean -nd

# DESTRUCTIVE: delete untracked files and directories (unrecoverable; not in reflog)
git clean -fd

# DESTRUCTIVE: also delete ignored files (.env, build output, local config)
git clean -fdx

# Interactive clean: hand to the user (prompts; hangs in a non-interactive shell)
git clean -i
```

## Worktrees

```bash
# List worktrees
git worktree list

# Add new worktree
git worktree add <path> <branch>
git worktree add ../project-feature feature-branch

# Add worktree for new branch
git worktree add -b <new-branch> <path>

# Remove worktree (refuses if it has uncommitted changes)
git worktree remove <path>

# Prune stale worktrees
git worktree prune
```

Advanced patterns (PR review, hotfix from tag, cleanup of merged worktrees): `modern-git-features.md`.

## Submodules

```bash
# Add submodule
git submodule add <url> <path>

# Initialize submodules (after clone)
git submodule init
git submodule update

# Clone with submodules
git clone --recurse-submodules <url>

# Update submodules
git submodule update --remote
git submodule update --init --recursive

# Execute command in all submodules
git submodule foreach <command>
git submodule foreach git pull origin main

# Remove submodule
git -C <path> status && git -C <path> log --branches --not --remotes   # check for unpushed work
git submodule deinit <path>
git rm <path>
# DESTRUCTIVE: deletes the submodule's repo, including unpushed commits. Confirm first.
# Directory is .git/modules/<name>; name usually equals path (check .gitmodules)
rm -rf .git/modules/<name>
```

## Tags and Releases

### Creating Tags

```bash
# Lightweight tag
git tag <tag-name>
git tag v1.0.0

# Annotated tag (recommended - includes metadata)
git tag -a <tag-name> -m "message"
git tag -a v1.0.0 -m "Release version 1.0.0"

# Tag specific commit (without -m an editor opens)
git tag -a <tag-name> <commit> -m "message"

# Signed tag (GPG signature)
git tag -s <tag-name> -m "message"
```

### Managing Tags

```bash
# List tags
git tag
git tag -l "v1.*"  # Pattern matching

# Show tag info
git show <tag-name>

# Delete local tag
git tag -d <tag-name>

# DESTRUCTIVE: delete remote tag (others may have fetched it). Confirm first
git push origin --delete refs/tags/<tag-name>   # full ref avoids clash with a same-named branch

# Push tags
git push origin <tag-name>
git push --tags          # All tags
git push --follow-tags   # Push commits plus annotated tags that point at them
```
