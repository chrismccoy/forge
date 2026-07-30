# Output Specification - Sections A-D

Emit exactly four sections, in order, no extras. Markdown body.

## Section A - Setup Summary

Maximum 3 lines. No prose paragraphs.

```
A) Setup Summary
- Market + offer type: <one-line restatement>
- Tone + audience: <one-line restatement>
- Domain and trademark checks: Needs verification.
```

## Section B - Name List (10 items)

Use this exact per-candidate block. Increment the number 1-10. Use the recommended TLD drawn from `EXTENSION_PRIORITY`.

```
# N) NameCandidate
- Angle: <1 sentence: what it evokes>
- Fit: <1 sentence tied to TARGET_AUDIENCE + OFFER_TYPE>
- Recommended extension: <one of EXTENSION_PRIORITY>
- Risk note: <Low | Medium | High> - <3-10 word reason>
```

Rules per block:

- **Angle**: must evoke something specific - a metaphor, motion, or quiet quality. Not generic.
- **Fit**: must reference the audience or offer concretely. Not "Great for founders" - say *why* it fits *this* founder.
- **Recommended extension**: pick from `EXTENSION_PRIORITY` only. Default to first listed if unclear.
- **Risk note** severity scale:
  - **Low** - invented or rare; no known major collision.
  - **Medium** - real-word compound; possible naming overlap; recommend trademark check.
  - **High** - close to a known brand, dictionary collision, or category-keyword overlap.

If fewer than 10 candidates clear the 7+ scoring threshold, emit only the ones that passed and append after the last block:

```
Returned N of 10 - niche requires looser scoring or revised inputs.
```

## Section C - Top 3 Shortlist

Rank the 3 best from Section B. Two bullets per ranked name.

```
C) Top 3 Shortlist

1. NameCandidate
  • Strength: <why it wins overall - brandability, niche fit, or rare combination>
  • Watch-out: <risk to monitor - collision, pronunciation edge case, TM exposure>

2. NameCandidate
  • Strength: ...
  • Watch-out: ...

3. NameCandidate
  • Strength: ...
  • Watch-out: ...
```

## Section D - Verification Checklist

Exactly 5 practical steps. No certainty claims. Each step is something the user can do, not something the assistant has done.

```
D) Verification Checklist
1. Check exact-match domain availability across EXTENSION_PRIORITY via a registrar (e.g., Cloudflare Registrar, Namecheap).
2. Run a USPTO TESS search for the bare term across IC 9, 35, 42 (software / SaaS classes).
3. Search WIPO Global Brand Database for international overlaps in your launch regions.
4. Pronounce the name to 3 strangers; ask them to spell it back without seeing it.
5. Google the name in quotes + your market keyword to surface accidental collisions.
```

## Worked Example - Single Candidate Block (calibration only)

Use only for tone and length reference. Do not reuse the name.

```
# 1) Nodelo
- Angle: Suggests a small, deliberate node in a larger system - quiet competence.
- Fit: Matches solo founders who want one calm hub instead of ten loud tabs.
- Recommended extension: .com
- Risk note: Low - invented, no known collisions.
```
