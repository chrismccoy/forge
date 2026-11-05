# Phase 5: Docs (WordPress-Docs to zero)

Run this phase only if the ruleset is the full `WordPress` standard.

Goal: every file, class, function, method, property and class constant documented the way WordPress-Docs requires, with a proof that only comments changed.

## What to write

`--standard` replaces the project ruleset, so select the Docs sniffs instead. List them and keep the plugin's settings with:
```
DOCS=$(vendor/bin/phpcs --standard=WordPress-Docs -e | sed -n 's/^ *\([A-Z][A-Za-z]*\.[A-Za-z]*\.[A-Za-z]*\)$/\1/p' | paste -sd,)
vendor/bin/phpcs --sniffs="$DOCS"
```

Fix every report. To place the bulk of the tags:
1. Run `php <skill-dir>/scripts/docblocks.php --list <files> > <scratch>/docs.json`, which lists every description needed.
2. Write each description by hand in `<scratch>/docs.json`, after reading the code.
3. Run `php <skill-dir>/scripts/docblocks.php --apply <scratch>/docs.json --package <package> --map <scratch>/flatten-map.txt <files>`, adding `--since <version>` if intake chose it. It takes types from the declarations, and writes nothing while a description is missing.
4. Fix the rest by hand. `phpcbf` can't fix `Squiz.Commenting.InlineComment.InvalidEndChar`, and a long description that starts with a lowercase function name needs rewording, for example `The filesize() function returns...`.

- **File docblock** after `<?php`: a one-line summary of what the file holds, then `@package <package>`.
- **Class, interface, trait and enum docblocks:** a one-line summary of the role, from reading the code.
- **Function and method docblocks:** a one-line summary, then a `@param` for every parameter in order, and an `@return` unless the function returns nothing (`void` or a constructor). The sniffs don't require `@return`; this skill does.
  - The types in `@param` and `@return` must match the declarations: `@param int $post_id`, `@return array|WP_Error`. When the declaration is `mixed`, or there is none, write the type that the code really accepts. Use `@param array<string, mixed>` style only if the plugin already does.
  - Every `@param` gets a description that says what the value is, not just the name again.
  - Align the types, names and descriptions in a block, as `Squiz.Commenting.FunctionComment` expects. `phpcbf` fixes the alignment afterwards.
  - Add `@throws` where the function throws an exception that isn't caught inside it.
- **Property docblocks:** a one-line summary and `@var <type>`.
- **Hook callbacks:** say which hook calls the function, for example `Filters 'parent_file' to highlight the import screen.`
- **Inline comments:** start with a capital letter and end with `.`, `!` or `?` (`Squiz.Commenting.InlineComment`).
- Follow intake question 11 for `@since`: add it to new docblocks only if that answer says so. Keep existing tags either way. It doesn't apply to test docblocks unless the answer says so.

Write real descriptions. Never use filler such as `Constructor.`, `Gets the thing.` or a summary that only repeats the name. A reviewer should learn something from each line.

## What not to touch

- `/* translators: */` comments: leave their text and position exactly as they are (Hard rule 4). WordPress-Docs already excludes the sniffs that would report them.
- `phpcs:` directives.
- Test annotations: `@runInSeparateProcess`, `@dataProvider` and the rest of the list in `phase-2-tier-a.md`.
- **Documented tests.** If intake chose it, `tests/` goes through the same steps. `Squiz.Commenting.FileComment` doesn't count a docblock followed directly by `require_once` as a file docblock, so put another statement between them, such as an assignment. That is a code change: commit it on its own first, and run the proof below against that commit. Docblocks that hold only annotations still need a summary added by hand. If `@since` applies to plugin code but not tests, run `--apply` twice. The script asks for `@return` only where a return type is declared. It prints `ADD @return` for each untyped function that returns a value: add those tags by hand.
- **Docblock placement in tests.** Where the first docblock in a file belongs to a class and carries annotations (for example `@runTestsInSeparateProcesses`), add the new file docblock *before* it, as its own comment with a blank line after it. The annotations must stay attached to the class.

## Prove the change is comment only

Run `php <skill-dir>/scripts/token-proof.php wpcs-v4-flatten --strip-comments`. Every file must report `OK`: the code tokens, the `phpcs:` directives and the test annotations must all be identical.

Run `phpcbf` once more afterwards for the alignment fixes, and run the proof again.

Run the tests (Hard rule 2), commit and tag `wpcs-v5-docs`, and update `WPCS_MIGRATION_LOG.md`.
