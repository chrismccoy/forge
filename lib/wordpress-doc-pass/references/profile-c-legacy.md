## PHP profile C: legacy / no standard

Match what is there. Consistency with the surrounding code beats any external standard.

- **Infer the conventions from the file itself:** indentation (tabs or spaces, and how many), docblock layout (`/**` alignment, whether tags are aligned), summary voice, and whether `@return void` is used. When a file has no existing docblocks, use the conventions of the most-documented file in the plugin. If there are none, fall back to profile A, since it's a WordPress plugin.
- **Respect the minimum PHP version in docblock types.** For PHP < 7.0 / 7.x code, document types *only* in docblocks (the code has no native types, so the docblock is the contract). Use simple, widely understood types: `int`, `string`, `bool`, `array`, `string[]`, `WP_Post|null`, and hash notation for argument arrays. Avoid PHPStan-only syntax unless a PHPStan / Psalm config exists.
- **Procedural plugins** (`functions.php`-style files, `include`d partials, function-prefix namespacing such as `myplugin_*`): document every function, including the ones hooked by string name. Note in the summary or description which hook calls it (`Hooked to 'admin_menu'.`). Use `@global` for `global $wpdb, $post, …`.
- **Old-style classes** (PHP 4-style constructors, `var` properties, static singletons): document them as they are. Never "fix" `var` to `public`, because that's a code change. Mention deprecated patterns as smells in the report.
- **Mixed-standard files:** follow each file's own dominant style. Don't normalize the whole plugin to one style. Note the inconsistency in the report.
- Keep accurate legacy comments if rewriting them would add nothing. `#` comments may stay `#` when the file uses them.
