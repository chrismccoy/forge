# Git Troubleshooting and Recovery

Reference for common problems, recovery scenarios, and emergency procedures.

Steps marked **DESTRUCTIVE** discard commits or working-tree changes. Before running one, follow the safety protocol in `dangerous-operations.md`: check `git status`, create a backup branch, and get the user's confirmation in the conversation.

## Common Problems

### Detached HEAD

```bash
# HEAD is detached: keep the commits made here by putting a branch on them
git branch <new-branch>     # name the current commit; nothing is lost now
git switch <new-branch>
```

Then ask the user what to do with the work: keep the branch, open a PR, or merge or cherry-pick it into another branch.

### Push Rejected (non-fast-forward)

```text
 ! [rejected]        main -> main (fetch first)
 ! [rejected]        main -> main (non-fast-forward)
```

The remote has commits the local branch lacks. Do **not** reach for `--force`.

```bash
git fetch origin
git log --oneline HEAD..@{u}     # commits on the remote missing locally
git log --oneline @{u}..HEAD     # local commits to push
git pull --rebase                # or: git pull --no-rebase (merge), per project convention
# resolve conflicts if any, then
git push
```

GH013 rejections (secrets, rulesets) are different; see `github-security.md`.

### Merge Conflicts

```bash
git status                              # see conflicted files; edit to resolve
git add <resolved-files>
GIT_EDITOR=true git merge --continue    # or: GIT_EDITOR=true git rebase --continue
git merge --abort                       # or git rebase --abort: start over
```

Details, including the `--ours`/`--theirs` swap during rebase: `merging-rebasing.md`.

### Accidentally Deleted Branch

```bash
# Find branch in reflog
git reflog
# Create branch at commit
git branch <branch-name> <commit-hash>
```

### Committed to Wrong Branch

```bash
# Move commit to correct branch
git switch correct-branch
git cherry-pick <commit>
git switch wrong-branch
git branch backup-wrong-branch           # safety net
# DESTRUCTIVE: only if the commit is not pushed; otherwise use git revert
git reset --keep HEAD~1                  # drop the commit; refuses if it would lose uncommitted changes
```

### Pushed Sensitive Data

1. **Rotate the credential first.** Rewriting history does not un-leak a pushed secret.
2. Then follow "Incident Response: Secret Leaked" in `security.md`. History rewrite steps live in `dangerous-operations.md` (Filter-Repo).

### Large Commit by Mistake

```bash
# Before pushing
git reset --soft HEAD~1
git reset HEAD <large-file>
echo "<large-file>" >> .gitignore        # or track it with LFS (performance-large-files.md)
git add .gitignore
git commit -m "message"

# After pushing: rewrite history with filter-repo (see dangerous-operations.md)
```

## Recovery Scenarios

### Recover After Hard Reset

```bash
git reflog                                  # find the commit before the reset
git status                                  # DESTRUCTIVE below: discards uncommitted changes
git branch backup-$(date +%Y%m%d-%H%M%S)
git reset --hard <commit-before-reset>
```

Safer alternative that touches nothing: `git branch recovered <commit-before-reset>`.

### Recover Deleted File

```bash
git log --all --full-history -- <file>
# DESTRUCTIVE if <file> exists locally: overwrites it. <commit> = the deleting commit
git restore --source=<commit>^ -- <file>
```

### Recover Deleted Commits

```bash
git reflog                       # find commit hash
git branch recovered <commit>    # safest: just name it
# or
git cherry-pick <commit>
# or
git merge <commit>
```

Moving the current branch with `git reset --hard <commit>` is **DESTRUCTIVE**. Create a backup branch first.

### Recover from Corrupted Repository

`git gc` does not repair corruption, and it can prune objects that might still be recovered. Do not run it here.

```bash
# 1. Back up the repository as-is
cp -a .git ../repo-git-backup

# 2. Find what is broken
git fsck --full

# 3. Re-download all objects from the remote (plain fetch skips objects Git thinks it has)
git fetch --refetch origin   # Git 2.36+

# 4. Still broken: fresh clone, then copy over unpushed work
git clone <url> ../repo-fresh
# copy changed files / cherry-pick commits recovered from the backup
```

## Undo a Force Push That Dropped Commits

**DESTRUCTIVE:** the final push overwrites the remote branch again. Follow the force-push protocol in `dangerous-operations.md` and get confirmation first.

```bash
git reflog show origin/<branch>               # old remote tip before the force push
git log --oneline <old-tip>..origin/<branch>  # commits others pushed since; keep them
git branch restore-<branch> <old-tip>
# Re-integrate any new commits, confirm with the team, then push with an explicit lease:
git push --force-with-lease=<branch>:<current-remote-sha> origin restore-<branch>:<branch>
```

## Quick Index

| Problem | Section |
|---------|---------|
| Undo last commit, keep changes | Large Commit by Mistake (`git reset --soft HEAD~1`) |
| Deleted branch | Accidentally Deleted Branch |
| Lost commits after reset | Recover After Hard Reset |
| Dangling commits | `git fsck --lost-found`, `git reflog --all` |
| Deleted file | Recover Deleted File |
