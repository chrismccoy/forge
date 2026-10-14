# Combining the Two Judge Runs

Each judge run sees the posts in one order. Run AB shows post 1 as A and
post 2 as B. Run BA shows post 2 as A and post 1 as B. Combine the two
replies into one report about **post 1** and **post 2**. Never report
"Post A" or "Post B" in the final output, because the labels mean different
posts in each run.

## 1. Check each run

A run **failed** only when it:
- returns no score table, or
- replies with a stop message: "I'm ready to compare the two blog
  posts...", "I have [Post A/B] but I'm missing the other post...", or
  "Post A and Post B appear to cover different topics...".

The opener "No [keyword/audience/goal] was provided — I'll infer it..." is
a normal reply when context is missing. It is not a failure.

On failure: rerun that order once. If it fails again, report the single
run's result and state that the position-bias check did not run. If both
runs return the "different topics" message, report that message and stop.

## 2. Read the scores

Read each run's `SCORES:` line (see the subagent brief in SKILL.md).

- Recompute each total as the sum of its 10 scores. Ignore `total_A` and
  `total_B` when they differ from the sum.
- Compare the 10 scores with the run's table. When they disagree, or the
  `SCORES:` line is missing or invalid JSON, use the table.

## 3. Map labels back to posts

| Run | Label A | Label B |
|---|---|---|
| AB | post 1 | post 2 |
| BA | post 2 | post 1 |

## 4. Average and measure bias

For each of the 10 criteria and for the total:

- average = (score in run AB + score in run BA) / 2, for each post
- keep one decimal place

**Order swing** = (post 2 total − post 1 total in run AB) − (post 2 total −
post 1 total in run BA). When |swing| is 6 or more, the judge leaned on
position. Report the swing in the output either way.

**Stability:**
- **Stable:** the same post has the strictly higher total in both runs.
- **Unstable:** the higher total flips between runs, or either run has
  equal totals.

## 5. Decision Rule for averaged scores

This rule replaces the Decision Rule in `judge-prompt.md`. Do not apply
that one.

Definitions:
- **Margin** = difference between the averaged totals.
- A post **clearly wins** a criterion when its average leads by 2.0 or
  more.

Apply in order and use the first outcome that matches:

1. **Merge** — margin of 5 or less AND each post clearly wins at least 3
   criteria.
2. **Merge** — margin of 5 or less AND unstable.
3. **Winner** — margin greater than 5. The post with the higher averaged
   total wins. If unstable, say the result depends on order and needs a
   human check. If the winner has a lower average on both Search Intent
   Alignment and Topical Depth, say so.
4. **Narrow win** — every other case. The post with the higher averaged
   total wins; on equal totals, the higher Search Intent Alignment average
   wins, then the higher Topical Depth average.

For a merge, the base post is the one with the higher averaged total; on
equal totals, the one with the higher Search Intent Alignment average.

## 6. Merge the qualitative sections

- **Search intent:** use the summary the two runs agree on. Note any
  disagreement.
- **Keep From the Other Draft / merge transplants:** take items named in
  both runs first. Add single-run items only when they cite specific text.
- **Flags:** take the union of both runs. Remove duplicates. A draft
  artifact or claim found by only one run still counts.
- **Top 5 fixes:** rank fixes named in both runs highest. Fill the rest by
  expected SEO impact. Exactly 5.
- **Title tag and meta description:** pick the best candidate from the two
  runs, or write a better one. Check both with the bundled script, never by
  eye:

  ```bash
  python3 ${CLAUDE_PLUGIN_ROOT}/lib/seo-duel/scripts/count_chars.py <<'EOF'
  title tag text
  ===
  meta description text
  EOF
  ```

  The script prints each count and exits 1 when the title tag is not under
  60 characters or the meta description is not under 155. Shorten and check
  again until both pass.

## 7. Final report format

1. **Search Intent Summary** (2-3 sentences)
2. **Averaged Score Table**

   | Criterion | Post 1 | Post 2 | Run AB (1/2) | Run BA (1/2) |
   |---|---|---|---|---|
   | ... one row per criterion ... | | | | |
   | **Total** | X/100 | X/100 | | |

3. **Stability:** stable or unstable, and the order swing in points.
4. **Verdict:** winner, narrow win, or merge, with a 3-5 sentence reason
   tied to the Decision Rule above.
5. **Keep From the Other Draft** (or merge plan with sections per post)
6. **Flags:** draft artifacts and claims to verify, each with location
7. **Top 5 Prioritized Fixes**
8. **Suggested Title Tag** and **Meta Description**, each with its
   character count from code
