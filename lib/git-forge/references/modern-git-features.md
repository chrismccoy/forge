# Modern Git Features (2.48+)

Reftables, sparse-checkout, partial clone, `git backfill`, path-walk packing, Scalar, advanced worktree patterns, and deprecations ahead of Git 3.0. Basic worktree commands live in `advanced-commands.md`; GC, LFS, and shallow clones (`--depth`, `--unshallow`) live in `performance-large-files.md`.

Check the installed version before recommending a feature:

```bash
git --version   # backfill needs 2.49+; repack --path-walk and stash import/export need 2.51+ (use 2.51.1+ for --path-walk)
```

## Release Highlights (selected)

| Version | Highlights |
|---------|------------|
| 2.48 | `git refs migrate` also migrates reflogs; more memory-leak fixes |
| 2.49 | `git backfill` (built on the path-walk API), `--name-hash-version=2` for pack-objects/repack, zlib code cleaned up in preparation for zlib-ng, Rust foreign-language interface, large-object promisor protocol extension, `.netrc` support re-enabled for HTTP |
| 2.51 | `git repack --path-walk` / `pack-objects --path-walk`, `git stash export` / `import` |
| 2.51.1, 2.52 | Fix for `repack --path-walk` losing objects in corner cases |
| 2.52 | `git repo info`, `git last-modified`, `git refs list` / `git refs exists`, `git sparse-checkout clean`; `main` declared the Git 3.0 initial-branch default |
| 2.53 | `git maintenance is-needed`, `git replay` (experimental) updates refs itself, `git blame --diff-algorithm` |

`--name-hash-version=2` and `--path-walk` are opt-in flags.

## Reftables

New ref storage format replacing loose ref files and `packed-refs`. Faster ref operations, atomic updates, better scaling with many refs.

**Use for:** repos with 10,000+ refs, CI systems creating many temporary refs, monorepos with heavy branching.

```bash
# Check current ref storage format
git rev-parse --show-ref-format

# Back up, preview, then migrate
cp -a .git ../repo-git-backup
git refs migrate --ref-format=reftable --dry-run
git refs migrate --ref-format=reftable

# Verify
git fsck --full
git log --oneline -5

# Roll back if needed
git refs migrate --ref-format=files

# Fails with "migrating repositories with worktrees is not supported yet":
# remove linked worktrees first (git worktree list)

# New repository with reftables
git init --ref-format=reftable
```

## Sparse-Checkout

Check out only a subset of files. Use for monorepos, large repos, and builds that need few paths.

**Cone mode (default, recommended).** `clone --sparse` enables cone mode already. `sparse-checkout init` is deprecated; use `set`.

```bash
git clone --filter=blob:none --sparse <repo-url>
cd <repo>

git sparse-checkout set src/api src/shared docs
git sparse-checkout add tests/integration
git sparse-checkout list

# Test whether paths match the rules (paths read from stdin)
echo src/api/users.ts | git sparse-checkout check-rules

git sparse-checkout disable
```

**Pattern mode (non-cone).** Deprecated per `git sparse-checkout` docs; prefer cone mode.

```bash
git sparse-checkout set --no-cone "*.md" "src/api/*" "!src/api/legacy/*"
git sparse-checkout set --no-cone --stdin < patterns.txt
```

**Reapply after a merge or rebase materialized unwanted files:**

```bash
git sparse-checkout reapply
```

## Partial Clone

Clone without downloading all objects. Missing objects fetch on demand from the promisor remote.

| Filter | Effect |
|--------|--------|
| `blob:none` | Defer all blobs (smallest, most common) |
| `tree:0` | Defer all trees and blobs |
| `blob:limit=1m` | Defer blobs of 1 MiB or more |

```bash
git clone --filter=blob:none <repo-url>
git clone --filter=blob:limit=10m <repo-url>

# Partial clone + sparse-checkout: objects only for chosen directories
git clone --filter=blob:none --sparse <repo-url>
cd <repo>
git sparse-checkout set --cone src/api

# Convert an existing clone to partial (future fetches only;
# objects already downloaded stay, so .git does not shrink)
git config extensions.partialClone origin
git config remote.origin.promisor true
git config remote.origin.partialclonefilter blob:none
git fetch

# Inspect
git config extensions.partialClone
ls -lah .git/objects/pack/*.promisor
git rev-list --objects --all --missing=print | grep '^?'   # list missing objects
```

## git backfill (2.49+)

Download missing blobs in a partial clone in batches grouped by path (path-walk API). Gives better delta compression than on-demand fetching.

```bash
git backfill                        # fetch all missing blobs reachable from HEAD
git backfill --sparse               # only blobs inside the sparse-checkout
git backfill --min-batch-size=1000  # objects per request
```

**Recipes:**

```bash
# Monorepo: one service, minimal download
git clone --filter=blob:none --sparse https://github.com/company/monorepo.git
cd monorepo
git sparse-checkout set --cone services/api
git backfill --sparse

# Long history: work on recent code now...
git clone --filter=blob:none https://github.com/project/with-long-history.git
cd with-long-history

# ...later, when full history is needed (e.g. before going offline)
git backfill
git repack --path-walk -a -d        # 2.51.1+; older Git: git repack -a -d -f
```

CI: use `actions/checkout` inputs (they handle auth for private repos):

```yaml
- uses: actions/checkout@v7   # current majors: github-actions.md
  with:
    filter: blob:none
    sparse-checkout: |
      src
      tests
```

Shallow `--depth=1` checkouts already fetch the blobs they need; `git backfill` adds nothing there.

## Path-Walk Packing

Path-walk groups objects by file path instead of commit order, so Git finds better delta bases. `git backfill` uses it automatically; repack needs the flag.

```bash
git repack --path-walk -a -d                    # 2.51.1+
git repack --name-hash-version=2 -a -d -f       # 2.49+ alternative
git repack -a -d -f --depth=250 --window=250    # aggressive fallback on older Git
git count-objects -v
```

## Promisor Remotes

Servers can advertise promisor-remote info to clients, improving lazy fetching of large objects.

```bash
git config remote.origin.promisor
git config extensions.partialClone

# Reset and re-enable a broken promisor configuration
git config --unset extensions.partialClone
git config --unset remote.origin.promisor
git config extensions.partialClone origin
git config remote.origin.promisor true
```

## Scalar (Large Repositories)

Ships with Git. `scalar clone` enables cone sparse-checkout, `blob:none` partial clone, multi-pack-index, commit-graph, and background maintenance in one step.

```bash
scalar clone --branch main <repo-url>
scalar register <path>      # existing clone: config + background maintenance only; no partial clone or sparse-checkout
scalar unregister <path>
```

**DANGER:** `scalar delete <path>` removes the whole enlistment directory from disk, working tree included. Before running it, check for unpushed work (`git status`, `git log --branches --not --remotes`, `git stash list`) and get explicit user confirmation.

## Worktrees: Advanced Patterns

Each worktree has its own index and HEAD. `.git/config` and `.git/info/exclude` are shared.

```bash
# PR review while coding (GitHub PR ref)
git fetch origin pull/123/head:pr-123
git worktree add ../myproject-pr-123 pr-123

# Hotfix from a tag
git worktree add --detach ../myproject-hotfix v1.2.3
cd ../myproject-hotfix
git switch -c hotfix/security-patch
git commit -am "fix: patch vulnerability"
git push -u origin hotfix/security-patch

# Central layout
mkdir -p ~/worktrees/myproject
git worktree add ~/worktrees/myproject/feature-a -b feature-a
```

List worktrees whose branch is merged into the current branch (skips the main worktree and the current branch). Show the list to the user, get confirmation in the conversation, then run `git worktree remove <path>` for each approved one:

```bash
main_wt=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
current=$(git branch --show-current)
git worktree list --porcelain | while IFS= read -r line; do
  case "$line" in
    "worktree "*) wt=${line#worktree } ;;
    "branch refs/heads/"*)
      branch=${line#branch refs/heads/}
      [ "$wt" = "$main_wt" ] || [ "$branch" = "$current" ] && continue
      git branch --format='%(refname:short)' --merged | grep -qxF "$branch" &&
        printf '%s\t%s\n' "$wt" "$branch" ;;
  esac
done
```

**Troubleshooting:**

```bash
git worktree unlock <path>                 # locked worktree
git worktree remove --force <path>         # DESTRUCTIVE: discards its uncommitted changes. Corrupted worktree only
git worktree prune
git checkout --ignore-other-worktrees <branch>   # branch checked out elsewhere (use with care)
```

## Choosing an Approach

| Situation | Use |
|-----------|-----|
| Monorepo, work on one area | Sparse-checkout (+ partial clone) |
| CI, large repo, good network | Partial clone (`blob:none`), optionally `--depth=1` |
| Frequent offline work | Full clone (partial clone needs network for missing objects) |
| Parallel branches, PR review mid-task | Worktrees |
| Huge monorepo, minimal disk | Scalar, or partial clone + sparse + `backfill --sparse` |

Illustrative only (actual savings depend on the repo): for a 5 GB repo, full clone ~5 GB; sparse ~500 MB; partial ~100 MB; partial + sparse ~50 MB.

**Migrating an existing large clone:**

```bash
git clone --filter=blob:none --sparse <url> large-project-new
cd large-project-new
git sparse-checkout set src/api src/shared
du -sh .git
# Delete the old clone only after confirming nothing unpushed remains there
```

## Git 3.0 Changes (Announced)

Planned default changes:
- reftable becomes the default ref format for new repositories (RelNotes 2.51).
- SHA-256 becomes the default hash function (2.51).
- `git init` uses `main` as the initial branch when not configured (2.52).

Planned removals:
- `git whatchanged`. Use `git log --raw` (2.51).
- Symlink symrefs (2.52).
- `.git/branches/` and `.git/remotes/` remote definitions (2.49).

Already removed: the recursive merge backend, in 2.50. `ort` replaced it, and `-s recursive` is now an alias.

Convert old-style remotes to `git remote`:

```bash
ls -la .git/branches .git/remotes 2>/dev/null
git remote rename origin origin     # Git's own migration: moves the file into config
git config --get-regexp '^remote\.origin\.'   # check url and fetch refspec
```

`git remote add origin` fails with "remote origin already exists" while the legacy file is present.

## Other Notes

- **`.netrc`:** HTTP transport reads `~/.netrc` again (2.49). Prefer a credential helper over plaintext tokens; see `security.md`.
- **Meson:** Alternative build system for Git itself, still maturing; `make` remains standard.

## Troubleshooting

```bash
# git backfill not found: needs 2.49+
git --version

# Sparse-checkout not applying
git config core.sparseCheckout
git config core.sparseCheckoutCone
git sparse-checkout reapply

# Missing object in partial clone
git fetch origin <commit>
git backfill
```

## Resources

- [Highlights from Git 2.49](https://github.blog/open-source/git/highlights-from-git-2-49/)
- [Partial clone](https://git-scm.com/docs/partial-clone)
- [git-sparse-checkout](https://git-scm.com/docs/git-sparse-checkout)
- [git-worktree](https://git-scm.com/docs/git-worktree)
- [Scalar](https://git-scm.com/docs/scalar)
