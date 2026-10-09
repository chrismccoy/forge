## PHP profile A: WordPress Coding Standards (WPCS / WordPress-Docs)

Follows the WordPress PHP Documentation Standards handbook. The `WordPress-Docs` sniffs (`Squiz.Commenting.*`, `Generic.Commenting.DocComment`) must pass.

- **Indentation:** tabs, when the file uses tabs (see the Universal rule on docblock indentation). Docblock lines are `<tab-indent> * text`. Align `@param` columns with spaces, but never re-space a Kept line to align it; align the new lines around it instead.
- **Summaries:** third-person singular verbs ("Registers the settings page.", "Retrieves the cached token."), one line, ending with a period. Descriptions are full sentences.
- **File docblock:** summary, optional description, `@package <Package>`, optional `@subpackage <Area>` (e.g. `Admin`, `REST`), and `@since`.
- **Class docblock:** summary, description, `@since`. For a class-scoped hook callback, the method docblock may say `Callback for the 'init' action.`
- **Tag order:** `@since`, `@deprecated`, `@access` (only for legacy code that already uses it), `@see`, `@link`, `@global`, `@param`, `@return`, `@throws`. Put one blank ` *` line between the description and the tags.
- **`@param` format:** `@param type $name Description.` For optional parameters write `Optional. Description. Default <value>.` Document an array-of-arguments parameter with WordPress hash notation:

  ```
   * @param array $args {
   *     Optional. Arguments for the query.
   *
   *     @type int    $limit Maximum results. Default 10.
   *     @type string $order Sort order. Accepts 'ASC', 'DESC'. Default 'DESC'.
   * }
  ```
- **`@return`:** document every non-void return, as in `@return int|false Post ID on success, false on failure.` Following the handbook, **omit `@return void`**, unless the project's phpcs ruleset requires it (check the `Squiz.Commenting.FunctionComment` config).
- **Types:** WordPress style. Use `int`, `bool`, `string`, `float`, `array`, `object`, `callable`, `mixed`, `null`, `false` and `true` (never `integer`, `boolean`, `double`). Write `string[]` / `int[]` for lists, `WP_Error` / `WP_Post` / `WP_REST_Request` with no leading backslash in the global namespace, and unions with `|`. Use generics / array shapes (`array<string, int>`, `array{...}`) only when the project already runs PHPStan / Psalm. Otherwise use hash notation.
- **Inline comments:** `//` followed by a space, starting with a capital letter and ending with a period (the `Squiz.Commenting.InlineComment` rules). Multi-line explanations use `/* … */` blocks. No `#` comments.
- **Hook docblocks:** a dynamic hook name is shown with braces in the summary and gets a `@param` description for the variable part. For example: ``Fires after a {$post_type} is imported.`` and "The dynamic portion of the hook name, `$post_type`, refers to the post type slug."
