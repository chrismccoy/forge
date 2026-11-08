# Conversion Rules

- Write every comment in plain, everyday English. Avoid jargon, abbreviations,
  and WordPress-internal shorthand where a simpler word works just as well (say
  "runs early in every WordPress request" instead of "fires on init", "checks
  permissions" instead of "validates capability", etc.) — assume the reader is
  new to this codebase or receiving it in a handoff.
- Plain words must stay true. State only what the code or the original comment
  shows. Do not guess when something runs, how often, or why, and do not widen a
  claim (say "throws on a failed download", not "throws if anything goes wrong").
  If no plain word is exact, keep the technical term. Keep function, hook, and
  option names exact.
- Strip @param, @return, @typedef, @package, @since boilerplate (unless the user
  said to keep them). Where the name and signature do not already make it clear,
  replace them with one short sentence saying what the function/method/hook does
  and, if helpful, why it exists. Leave no comment on constructors, simple
  getters, or anything else whose name says it all.
- For hook registrations (`add_action`, `add_filter`), keep a short plain-English
  note on what triggers the hook and what it's used for, if the user opted to
  preserve this.
- Collapse multi-property array/object shape descriptions (e.g. a post meta
  array, a REST response shape) into compact single-line comments near their
  first use, described in plain terms (e.g. "a product record: id, name, price,
  stock count").
- Preserve only comments that add real value (non-obvious behavior, timing
  quirks, security checks, edge cases, invariants) — delete comments that just
  restate the code. This covers existing inline `//` comments as well as doc
  blocks.
- Never put `?>` in a `//` comment or `*/` in a block comment. Leave JSX comments
  as `{/* */}`. Keep the comment type wherever a line comment would change
  parsing, such as one-line `<?php /** ... */ ?>` in templates.
- Do not alter any executable logic, formatting conventions, hook names, text
  domains, or public API surface (function signatures, REST routes, shortcode
  tags, filter/action names).
