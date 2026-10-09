## PHP profile B: PSR-12 / PER (PSR-5/19-style PHPDoc)

- **Indentation:** spaces (usually 4), matching the file. Line limit as configured (default 120).
- **Summaries:** a short sentence ending with a period. The imperative or third person both work, but be consistent within the project.
- **File docblock:** summary, optional description, `@package <Package>`.
- **`@since`:** only when the project already uses `@since` in its docblocks. Otherwise omit it everywhere; the coverage scan then skips the `@since` check.
- **`@return`:** always, including `@return void` and `@return never`.
- **Types:** precise and modern. Use `array<string, mixed>`, `list<int>`, `array{key: type}` shapes, `int<0, max>`, `class-string<Foo>`, `callable(string): bool`, and `\WP_Error` / `\WP_Post` with a leading backslash inside namespaced files unless the class is imported with `use`.
- **Don't duplicate a native type with a vaguer one.** If the signature says `array`, the docblock should refine it (`list<string>`), not repeat `array`.
- **Inline comments:** `//` comments are full sentences ending with a period.
