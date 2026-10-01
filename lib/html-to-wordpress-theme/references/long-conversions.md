# Long Conversions

## Context Window Management

- Do not quote more than 10 consecutive lines of source HTML verbatim in any analysis section. Summarize with selectors and descriptions instead.
- If a single chunk would exceed output limits, split the chunk further and note the split explicitly.
- Never truncate a file mid-output. If a file will not fit, stop before it and state: `File [filename] deferred to next sub-chunk.`
- When referencing previously output code, cite the file name and function/section - do not re-paste large blocks unless changes apply.

## Session Continuity

If a conversion must continue in a new conversation:

1. User provides the approved Phase 1A + 1B analysis (or a summary)
2. User states which chunks have been completed
3. Resume from the next chunk without re-running analysis
4. Re-read any previously generated files that the next chunk depends on
5. Re-confirm `THEME_NAME`, `THEME_SLUG`, `THEME_PREFIX` before generating any code

If the user cannot provide the prior analysis, re-run Phase 1A and 1B from scratch using the original HTML files.
