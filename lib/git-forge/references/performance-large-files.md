# Git Performance, Large Files, and Maintenance

For partial clone, sparse-checkout, `git backfill`, reftables, and Scalar, see `modern-git-features.md`.

## Repository Maintenance

```bash
# Garbage collection
git gc
git gc --aggressive  # More thorough, slower

# DESTRUCTIVE: prune unreachable objects (lost commits become unrecoverable).
# Prefer git gc. Bare git prune has no grace period unless --expire is given
git prune --expire=2.weeks.ago

# Verify repository
git fsck
git fsck --full

# Optimize repository
git repack -a -d -f --depth=250 --window=250   # -f recomputes deltas

# Path-walk / name-hash repacking (2.49+/2.51+): see modern-git-features.md

# Count objects
git count-objects -v

# Repository size
du -sh .git
```

## Large Files

```bash
# Find large files in history
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort --numeric-sort --key=2 |
  tail -n 10

# Git LFS (Large File Storage)
git lfs install
git lfs track "*.psd"
git lfs track "*.zip"
git add .gitattributes
git add file.psd
git commit -m "Add large file"

# Files already committed stay in history as normal blobs. Moving them to LFS
# rewrites history: follow dangerous-operations.md first
git lfs migrate import --include="*.psd" --everything

# List LFS files
git lfs ls-files

# Fetch LFS files
git lfs fetch
git lfs pull
```

## Shallow Clones

```bash
# Shallow clone (faster, less disk space)
git clone --depth 1 <url>

# Unshallow (convert to full clone)
git fetch --unshallow

# Fetch more history
git fetch --depth=100
```
