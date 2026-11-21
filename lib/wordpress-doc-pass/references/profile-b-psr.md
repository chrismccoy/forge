## PHP profile B: PSR-12 / PER (PSR-5/19-style PHPDoc)

- **Indentation:** spaces (usually 4), matching the file. Line limit as configured (default 120).
- **Summaries:** a short sentence ending with a period. The imperative or third person both work, but be consistent within the project.
- **File docblock:** summary, optional description, `@package <Package>`.
- **`@since`:** only when the project already uses `@since` (more than half of its existing docblocks carry one); new ones take the plugin or theme header's Version. Otherwise omit it everywhere; the coverage scan then skips the `@since` check.
- **`@return`:** always, including `@return void` and `@return never`.
- **Types:** precise and modern. Use `array<string, mixed>`, `list<int>`, `array{key: type}` shapes, `int<0, max>`, `class-string<Foo>`, `callable(string): bool`, and `\WP_Error` / `\WP_Post` with a leading backslash inside namespaced files unless the class is imported with `use`.
- **Don't duplicate a native type with a vaguer one.** If the signature says `array`, the docblock should refine it (`list<string>`), not repeat `array`.
- **Inline comments:** `//` comments are full sentences ending with a period.

### Terse form

- **Form:** a one-line docblock, `/** Gets the invoice total. */`. No `@param` or `@throws`. Profile B's `@return` rule (always, including `void`) applies to Full only; in terse the `@return` line goes unless checked types keep it.
- **Typed tags:** PHPStan or Psalm configured means checked types are on, so existing typed tags stay (one line each, the description may shrink); never add one. Class tags and `@phpstan-type` / `@psalm-type` always stay. `@since` follows profile B's rule: omitted unless the project already uses it.
- **Doc-requiring lint rules** that terse raises: `Squiz.Commenting.*` or `Generic.Commenting.*` only when the ruleset includes them (a plain `PSR12` ruleset has none). PHPStan rules about missing `@param` / `@return` types (`missingType.*`) rise when checked types are off and the native types are not enough.
