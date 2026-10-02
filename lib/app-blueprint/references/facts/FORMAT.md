# Fact sheet format

Fact sheets hold framework and service behavior that blueprint authors
commonly get wrong. `REVIEW.md` checks a blueprint against every fact that
applies to its stack. A fact belongs here only if getting it wrong changes a
design or breaks a build. Trivia, style advice and marketing claims do not
belong.

## File layout

```
# <STACK> facts
Covers: <frameworks and tools, from the TECH_STACK lines of support-files/<STACK>.md>
Verified: <YYYY-MM-DD> against official documentation. Re-verify facts older than 12 months.

## <Topic, e.g. Data model / REST API / Auth / Caching / Jobs / Testing / Deploy>

### <ID> <Short title>
- Trap: <what a blueprint typically assumes or writes, stated as the wrong belief>
- Reality: <the actual behavior, with versions where behavior changed>
- Detect: <words or designs in a blueprint that signal the trap>
- Fix: <the correct approach, one or two sentences>
- Source: <official doc page title> - <URL>
```

## Rules

- **IDs:** stack prefix plus a number, e.g. `WP-07`, `TS-12`, `SVC-03`.
  Never renumber an ID once it is published. Retire a fact by marking it "(retired)".
- **Verification:** every fact is verified against official documentation (or
  the source code / changelog when the docs are silent). If you cannot verify
  a fact, leave it out. Never pad a sheet with plausible-sounding claims.
- **Versions:** version-qualify any behavior that changed across major
  versions (e.g. "Next.js 15+: fetch is not cached by default").
- **Size:** keep each sheet at or under 16 KB (16,384 bytes) so that it fits in
  a chat context next to REVIEW.md, a blueprint and two or three other sheets.
  Prioritize by damage × frequency; when a sheet is full, tighten wording or
  retire the least damaging fact.
- **Ordering:** order topics by how often blueprints break them, not
  alphabetically.
