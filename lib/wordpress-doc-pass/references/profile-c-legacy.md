## PHP profile C: legacy / no standard

Match what is there. Consistency with the surrounding code beats any external standard.

- **Infer the conventions from the file itself:** indentation (tabs or spaces, and how many), docblock layout (`/**` alignment, whether tags are aligned), summary voice, and whether `@return void` is used. When a file has no existing docblocks, use the conventions of the most-documented file in the project. If there are none, fall back to profile A, since it's WordPress code.
- **Respect the minimum PHP version in docblock types.** For PHP < 7.0 / 7.x code, document types *only* in docblocks (the code has no native types, so the docblock is the contract). Use simple, widely understood types: `int`, `string`, `bool`, `array`, `string[]`, `WP_Post|null`, and hash notation for argument arrays. Avoid PHPStan-only syntax unless a PHPStan / Psalm config exists.
- **Procedural code** (plugins and classic themes built from `functions.php`-style files, `include`d partials, and function-prefix namespacing such as `myplugin_*`): document every function, including the ones hooked by string name. Note in the summary or description which hook calls it (`Hooked to 'admin_menu'.`). Use `@global` for `global $wpdb, $post, …`.
- **Old-style classes** (PHP 4-style constructors, `var` properties, static singletons): document them as they are. Never "fix" `var` to `public`, because that's a code change. Mention deprecated patterns as smells in the report.
- **Mixed-standard files:** follow each file's own dominant style. Don't normalize the whole project to one style. Note the inconsistency in the report.
- Keep accurate legacy comments if rewriting them would add nothing. `#` comments may stay `#` when the file uses them.

### Terse form

- **Form:** a one-line docblock in the surrounding voice (a file that uses `#` comments or no summary period keeps that form). No `@param`, `@return` or `@throws`, unless checked types keep them. Procedural code gets its line on every function, with the hook in it only when the registration does not show it (`Hooked to 'admin_menu'.`); existing `@global` lines stay, and none is added.
- **Old-style classes** (`var`, PHP 4 constructors) are documented as they are, one line each; the code stays.
- **Doc-requiring lint rules:** none by default (profile C has no ruleset). When a ruleset exists, follow the profile A list.
- Consistency still wins: in a mixed file, condense in the file's own style and leave accurate short comments as they are.
