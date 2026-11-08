# Intake Questions

Ask one at a time, in order. Skip a question only if the user already answered it
during this run.

1. Which file(s) should this run on? (Take paths if files can be read directly.
   Otherwise ask the user to paste whole files.)

2. Scope: Convert every doc block, or only certain kinds (e.g. skip theme/plugin
   header comments, skip @param/@return docs on trivial one-liners, skip
   docblocks on hook callbacks vs. core functions)?

3. Hooks: For `add_action` / `add_filter` registrations and the doc blocks above
   `do_action()` / `apply_filters()` calls, keep a short note on what the hook is
   for and when it runs, drop them, or leave them exactly as they are (e.g.
   because WPCS or phpDocumentor reads them)?

4. Style preference: `//` line comments only, or is a short `/* ... */` block okay
   for multi-line summaries (e.g. file header, class summary)?

5. Header: Keep the comment at the top of the file exactly as it is, or simplify
   it too? (Plugin and theme headers always stay.)

6. Anything else that must NOT be touched (e.g. specific hook callback signatures
   other tools rely on doc-comments for, REST API endpoint docs, Composer/WP-CLI
   command docs, or `@since`/`@package` tags required by a documentation
   generator)?
