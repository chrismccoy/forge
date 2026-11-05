# Generating the Document

Follow these sections in order. "Item N" refers to the intake form in the
procedure's `${CLAUDE_PLUGIN_ROOT}/lib/latex-generator/SKILL.md`.

## A. Document structure

- **Preamble:** Load a package from the standard safe set (amsmath, amssymb,
  amsthm, mathtools, hyperref, cleveref) only when the document uses it. Every
  other package must trace to a specific intake answer, for example:
  - `tikz` when item 6 uses TikZ, or `pgfplots` when item 6 uses `\addplot3`
  - `graphicx` when item 6 uses an external image
  - `algorithm`/`algorithmic` or `algorithm2e` when item 9 requests pseudocode
  - `biblatex` when item 8 = (b) and item 10 = (b)
  - plain `thebibliography`, with no package, when item 8 = (b) and item 10 = (a)

  Load `hyperref` after other packages, except `algorithm`, which follows it.
  Load `cleveref` last.
- **Cross-references:** In article output, environments that share a counter
  make `\cref` print the wrong name, such as "theorem 1.2" for a lemma, with no
  log warning. Give every such environment, including definitions and examples,
  a typed label, for example `\label[lemma]{...}`.
- **Front matter:** Title. Leave `\author` empty or use a stated name, and never
  invent one. Include an abstract when item 3 = (c), and when item 3 = (b) in a
  document over 5 pages. Always omit it for item 3 = (a), for Beamer, and for
  problem sets.
- **Sections:** Follow the scope limit from item 4.
- **Table of contents, appendices, glossary:** Omit unless the scope limit is
  large enough to warrant them, roughly more than 10 pages or more than 5 major
  results. State any skip due to scope explicitly, in one line of the Section E
  exclusion note.

### Beamer (item 7 = (b))

- Do not load amsmath, amssymb, amsthm, or hyperref. Beamer loads them.
- Do not redefine its predefined environments: `theorem`, `lemma`, `corollary`,
  `fact`, `problem`, `solution`, `definition`, `definitions`, `example`,
  `examples`, and `proof`. When `proposition` is used, define it with
  `\newtheorem{proposition}[theorem]{Proposition}`, because the predefined
  environments share one counter.
- Use `\ref`, not `cleveref`.
- Use `\setbeamertemplate{theorems}[numbered]` and
  `\setbeamertemplate{caption}[numbered]` when numbers are referenced.
- Place one idea on each frame. Mark a frame `[fragile]` when it holds verbatim
  content. Keep floats in place, using `algorithm2e` with `[H]` for pseudocode.
- Add `\resetcounteronoverlays{algocf}` when pseudocode sits on a frame with
  overlays. Otherwise each overlay advances the algorithm number.
- Do not use `allowframebreaks`. Split a long proof across consecutive frames,
  and count each frame.
- Omit the table of contents unless the user asks for it.
- Place references on the last frame, after any Caveats frame. It counts toward
  scope. Add `\setbeamertemplate{bibliography item}{\insertbiblabel}`, because
  the default icons leave `\cite` numbers with nothing to match.

### Problem sets

- Number the problems in one list. Count each numbered problem once, whatever its
  parts.
- Make every problem well-posed, solvable at the item 2 level, and solved in
  drafting, even when solutions are not delivered.
- When solutions are wanted, place them in a section after all the problems and
  before any Caveats section, with matching numbers, so that problems appear
  without their answers. The Section B proof and intermediate-step rules apply
  to these solutions.
- When solutions are not wanted, state no answers, and skip the Section B rules
  on proofs and worked examples.

## B. Mathematical content rules

- State complete hypotheses in every theorem and lemma.
- For item 3 = (b) or (c), write complete proofs, with no "it can be shown
  that". Do not cite a result the document relies on in place of a proof, unless
  it is within the item 2 prerequisites. For item 3 = (a), sketches are
  acceptable but must be labeled as sketches.
- Show intermediate steps in worked examples, not just final answers, using the
  precision or rounding convention from item 5. Include worked examples at item
  3 = (b) unless a content count excludes them or the user says no examples. A
  pure proof-based approach does not rule them out.
- When a claim, bound, or numerical result cannot be verified by reasoning shown
  in the document, flag it explicitly in a final unnumbered section titled
  "Caveats / Unverified Claims", or a frame for Beamer, placed before the
  references, rather than asserting it as settled. This counts toward scope. Omit
  it when there is nothing to flag. Results within the item 2 prerequisites,
  results cited from a listed reference, and labeled sketches of established
  results need no flag.

## C. Visualization rules

- Produce only the exact figures specified in item 6.
- Give each figure a caption describing what it proves or illustrates.
- Reference each figure from the body text via `\cref` or `\ref`.

## D. Compile and self-check

**Compile first.** When a TeX engine is available, compile in a temporary
directory, copying in the .bib and any supplied images, so that build files stay
out of the deliverable.

- Use `latexmk -pdf` when present. Otherwise run `pdflatex` twice, or `pdflatex`,
  `biber`, `pdflatex`, `pdflatex` when `biblatex` is used.
- Fix compile errors, for at most 3 attempts, then report what remains.
- Treat `Overfull \vbox` in a Beamer log as a failure, because frame text is cut
  off with no error. Fix any `Overfull \hbox` in either format.
- Check the printed reference names in the PDF, for example with `pdftotext`.
- When a user-supplied image is absent, compile a temporary copy with a stand-in
  image and report that. Keep the `\includegraphics` line, and never remove a
  requested figure. Name the expected filename in Section E, and leave the figure
  checklist item unticked.
- Use the PDF to check the page count. For Beamer, count frames, not PDF pages,
  because overlays add pages.

Without an engine, count Beamer frames in the source. For article output,
estimate the page count at roughly 400 words per page for the default layout.

**Then perform this check and show it as a short checklist.** For any item that
fails, do one of the following:

1. Revise the document to fix it before delivering, and note what was changed.
2. When it cannot be fully resolved within the stated scope, explicitly flag the
   unresolved issue to the user alongside the deliverable.

Never mark an item as passed unless it was fully satisfied. Mark an item that
does not apply as `[N/A]`.

**Revision method:** Prefer a minimal, targeted edit to the affected section
over regenerating the document. Regenerate in full only when the fix requires
restructuring most of the document, such as a scope-limit violation that needs
content re-balanced across all sections. Recompile after every revision when an
engine is available.

**Cutting to fit:** When the compiled length is above a stated range, or past
the limit for a single page count, cut supporting material and list what was cut
in Section E. Never cut a requested result, figure, or extension without asking.
Never replace the proof of a result the document relies on with a citation,
unless the result is within the item 2 prerequisites. Cut the example or remark
that needs it, or flag the overrun. Do not change the font size or margins to
hit a page count. Flag a document that falls short of the scope rather than
padding it.

**Scope tolerance:** Land within approximately ±15% of a page count. For a range
such as "6-8 pages", land inside the range. The ±15% limit on its endpoints is
the outer bound, and with page-only scope any result outside the range must be
flagged in Section E, with the scope item left unticked. Match a content count
exactly: for "2 theorems, 3 lemmas", deliver exactly that many, not roughly that
many. Match a slide count exactly, or land inside a slide range. When a page
count and a content count are both given, the stated page count, or the upper
end of a range, is a ceiling with no lower bound and no added 15%. A slide count
stays exact, and a slide range stays a range. An overrun means going past these
limits. References and any Caveats section count toward pages. Check content and
frame counts from the source. Without an engine, leave an article page-count
item unticked, mark it "estimated: N pages, unverified", and list it in Section
E.

- [ ] All theorem hypotheses stated completely
- [ ] All proofs complete per chosen rigor level (sketches only for item 3 =
      (a), and labeled)
- [ ] Notation used consistently throughout
- [ ] Level matches the item 2 audience and prerequisites
- [ ] Figure/equation/theorem numbering is consistent and referenced, and each
      printed reference shows the right name and number
- [ ] Package list matches only what's actually used in the document
- [ ] Scope limit from item 4 respected, per the tolerance above
- [ ] Each figure matches item 6, has a caption, and is referenced
- [ ] Each item 9 extension is present
- [ ] Numeric worked examples follow the item 5 convention
- [ ] For item 8 = (b), 3-5 references or the user's confirmed count, each one
      cited
- [ ] For a problem set, solutions delivered as the user answered
- [ ] Any unverifiable claims listed in a Caveats section

**Limitation:** This is a logical and structural check performed by reasoning
over the generated content. A compile confirms syntax and page count only, not
the mathematics. Flag this to the user, and state whether the document was
compiled.

## E. Deliverable

Provide exactly the file(s) chosen in item 10, plus any extras explicitly
requested under that item. Treat the compiled PDF as a build file unless the
user asks for it. Without file tools, present them in fenced code blocks. With
file tools, write them to the working directory, named after the topic in
kebab-case, with a `-slides` suffix for Beamer. Do not overwrite an existing
file without asking, except for an edit the user requested to a file delivered
in this conversation. Add the following:

- The Section D checklist, with what was changed to pass it.
- The compile result, or a statement that the document was not compiled, with
  the self-check limitation from Section D.
- A short "Compile Instructions" block of 2-4 lines, for example `pdflatex`
  twice for cross-refs, or `biber` when `biblatex` is used.
- A note of up to 5 lines on what was intentionally excluded due to scope,
  including anything cut to fit, so that the user knows what to ask for in a
  follow-up. Write "None" when nothing was excluded.
- Any deferred format from item 7.
- Any unresolved issues from the self-check, listed clearly here rather than
  buried in the checklist.
- For item 8 = (b), a notice that real titles and authors were used, but that
  citation details cannot be guaranteed and should be verified by the user before
  submission. Explicitly name any model-selected entries as substitutions.

After delivering the file(s) and these notes, end the turn. Do not proactively
ask "want revisions?" or continue iterating unprompted. Wait for the user's
follow-up.
