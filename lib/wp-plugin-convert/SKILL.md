# WordPress plugin conversion: WPCS and modern PHP, either way

This procedure routes to one of two complete procedures. It holds no conversion rules of its own.

`<skill-dir>` isn't used here: each procedure below defines its own.

| Direction | Procedure | Result |
|-----------|-----------|--------|
| WPCS to modern | `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-modernize/SKILL.md` | PSR-12, a PSR-4 `src/` tree grouped by role, strict PHP 8.1 types |
| Modern to WPCS | `${CLAUDE_PLUGIN_ROOT}/lib/wp-wpcs/SKILL.md` | A WPCS ruleset, snake_case names, WordPress class and file names in `includes/`, coercive typing |

## 1. Check the plugin

Run from the plugin's root directory. If no PHP file in the root has a `Plugin Name:` header, stop: this is not a WordPress plugin and this procedure doesn't apply.

## 2. Check for a run in progress

Read the log and tags before asking anything: `git tag --list` and any log in the plugin root.
- `WPCS_MIGRATION_LOG.md` or `wpcs-v*` tags with no `wpcs-v8-verified`: a modern-to-WPCS run is in progress. Resume it.
- `MIGRATION_LOG.md` or `v*` tags with no `v7-verified`: a WPCS-to-modern run is in progress. Resume it.

A resumed run skips step 3. A finished run in either direction is history, not a resume: go on to step 3.

## 3. Choose the direction

Read the code outside `vendor/`, `node_modules/` and `build/`, and count these signals:

| Signal | Points to the plugin being |
|--------|----------------------------|
| `namespace` lines, classes in `src/`, `declare(strict_types=1)`, camelCase methods, space indentation | modern, so modern to WPCS is the likely request |
| Prefixed global classes, `includes/class-*.php`, snake_case methods, tab indentation | WPCS, so WPCS to modern is the likely request |

If the request names the target style, use that direction and say which one was chosen. Otherwise ask with `AskUserQuestion`, both directions as options. Make the direction the code points to the first option, marked "(Recommended)", and say what the code showed. With mixed signals, recommend neither.

If the request names a target the plugin already meets, say so and ask before going on.

## 4. Load one direction

Read that direction's procedure file in full, and follow it to the end, as the only instructions for this run.
- **Never read the other direction's files during a run.** Their hard rules contradict each other: camelCase and snake_case, adding and removing `strict_types`.
- One run converts one way. To go back afterwards, start a new run: the modern-to-WPCS procedure uses the records an earlier WPCS-to-modern run left, and each direction keeps its own tags and log.
