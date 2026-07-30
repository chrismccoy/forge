#!/usr/bin/env bash
# map-history.sh - Looks at a project's git history so the changelog skill knows
# what it is working with.
#
# It prints a few clearly labeled sections: whether the folder is a real git
# project, where the very first change is, which releases are tagged, and the
# full list of changes from oldest to newest. It only reads. It never changes
# anything in the project.
#
# How to run it: map-history.sh [folder]   (uses the current folder if none given)

set -uo pipefail

REPO="${1:-.}"
cd "$REPO" 2>/dev/null || { echo "STATUS: not-a-directory"; exit 2; }

# --- Is this a git project at all? ------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "STATUS: not-a-git-repo"
  echo "Stop: '$REPO' is not a git project. Tell the user and do not make up a changelog."
  exit 2
fi

SHALLOW=$(git rev-parse --is-shallow-repository 2>/dev/null)
COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo 0)

echo "STATUS: ok"
echo "SHALLOW: ${SHALLOW}"          # true means only part of the history is here, so we cannot claim to cover all of it
echo "COMMIT_COUNT: ${COMMIT_COUNT}"

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "Stop: this project has no changes recorded yet."
  exit 0
fi

# --- The very first change --------------------------------------------------
# To include the first change in a range, write root..X, not root^..X, because
# the first change has nothing before it.
echo "=== ROOT_COMMIT (git rev-list --max-parents=0 HEAD) ==="
git rev-list --max-parents=0 HEAD

# --- Which releases are tagged ----------------------------------------------
echo "=== TAGS (git tag -l --sort=creatordate) ==="
git tag -l --sort=creatordate | sed 's/^/tag: /'
echo "=== END_TAGS ==="

# --- Every change, oldest first ---------------------------------------------
# Group these by day to spot where one release or era ends and the next begins.
echo "=== TIMELINE (git log --reverse --format='%ci %h %s') ==="
git log --reverse --format='%ci %h %s'
echo "=== END_TIMELINE ==="

# --- The big picture of what changed ----------------------------------------
echo "=== DIFFSTAT_ROOT..HEAD (git diff <root>..HEAD --stat) ==="
ROOT=$(git rev-list --max-parents=0 HEAD | head -n1)
git diff "${ROOT}..HEAD" --stat 2>/dev/null || echo "(only one change in this project: look at it directly with git show ${ROOT})"
echo "=== END_DIFFSTAT ==="
