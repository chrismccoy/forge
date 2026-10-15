# Merging, Rebasing, Cherry-Pick

Reference for combining branches. Rebase rewrites local history; force-pushing the result is covered in `dangerous-operations.md`.

**Non-interactive:** `--continue` and a plain `git commit` after a conflict open an editor. Prefix them with `GIT_EDITOR=true` to accept the prepared message.

## Merge Strategies

```bash
# Fast-forward merge (default if possible)
git merge <branch>

# Force merge commit (even if fast-forward possible)
git merge --no-ff <branch>

# Squash merge (combine all commits into one)
git merge --squash <branch>
# Then commit manually: git commit -m "Merged feature X"

# Merge with specific strategy
git merge -s ort <branch>        # Default since Git 2.34; since 2.50 "recursive" is an alias for ort
git merge -s ours <branch>       # Record a merge but keep our tree entirely (discard theirs)
# There is no "-s theirs" strategy. For "their version on conflicts" use -X theirs (below).
git merge -s octopus <branch1> <branch2> <branch3>  # Merge multiple branches

# Merge with strategy options
git merge -X ours <branch>     # Prefer "our" changes in conflicts
git merge -X theirs <branch>   # Prefer "their" changes in conflicts
# During a rebase, ours/theirs are SWAPPED: "ours" is the branch being rebased onto
# (upstream) and "theirs" is your own commit being replayed
git merge -X ignore-all-space <branch>
git merge -X ignore-space-change <branch>

# Abort merge
git merge --abort

# Continue after resolving conflicts
GIT_EDITOR=true git merge --continue
```

## Conflict Resolution

```bash
# When merge conflicts occur
git status  # See conflicted files
```

Conflict markers in files:

```text
<<<<<<< HEAD
Your changes
=======
Their changes
>>>>>>> branch-name
```

```bash
# Resolve conflicts manually, then:
git add <resolved-file>
git commit --no-edit  # Complete the merge with the prepared message

# Use mergetool (interactive: hand to the user)
git mergetool

# Accept one side completely (discards the other side's changes to <file>)
# In a REBASE these swap: --ours = upstream, --theirs = your commit being replayed
git checkout --ours <file>    # Merge: keep current branch's version
git checkout --theirs <file>  # Merge: keep the merged branch's version
git add <file>

# View conflict diff
git diff           # Show conflicts
git diff --ours    # Compare with our version
git diff --theirs  # Compare with their version
git diff --base    # Compare with base version

# List conflicts
git diff --name-only --diff-filter=U
```

## Rebase Operations

**WARNING: Rebase rewrites history. Never rebase commits that have been pushed to shared branches.**

```bash
# Basic rebase
git rebase <base-branch>
git rebase origin/main

# Interactive rebase (POWERFUL). Opens an editor: hand to the user,
# or script the todo list with GIT_SEQUENCE_EDITOR
git rebase -i <base-commit>
git rebase -i HEAD~5  # Last 5 commits
```

**Interactive rebase commands:**

```text
p, pick     = use commit
r, reword   = use commit, but edit message
e, edit     = use commit, but stop for amending
s, squash   = use commit, but meld into previous commit
f, fixup    = like squash, but discard commit message
x, exec     = run command (rest of line) using shell
b, break    = stop here (continue rebase later with 'git rebase --continue')
d, drop     = remove commit
l, label    = label current HEAD with a name
t, reset    = reset HEAD to a label
m, merge    = create a merge commit (used by --rebase-merges)
u, update-ref = update a ref to this point (used by --update-refs)
```

```bash
# Rebase onto different base
git rebase --onto <new-base> <old-base> <branch>

# Continue after resolving conflicts
GIT_EDITOR=true git rebase --continue

# Skip current commit
git rebase --skip

# Abort rebase
git rebase --abort

# Preserve merge commits
git rebase --rebase-merges <base>    # (--preserve-merges was removed in Git 2.34)

# Autosquash (with fixup commits)
git commit --fixup <commit>
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <commit>^   # non-interactive; base must precede the target
```

## Cherry-Pick

```bash
# Apply specific commit to current branch
git cherry-pick <commit>

# Cherry-pick multiple commits
git cherry-pick <commit1> <commit2>
git cherry-pick <commit1>^..<commit5>   # commit1 through commit5 (A..B would exclude A)

# Cherry-pick without committing
git cherry-pick -n <commit>
git cherry-pick --no-commit <commit>

# Continue after resolving conflicts
GIT_EDITOR=true git cherry-pick --continue

# Abort cherry-pick
git cherry-pick --abort
```
