# Iterate, Record, Review and Report

Steps 7 to 9 in detail.

## Contents

1. Fast runs
2. Failures
3. Side-effect tally
4. Recording and contact sheets
5. Report

## 1. Fast runs

```sh
node --env-file=.env record.js <plugin-slug>.scenes.js --fast --only settings,search
node --env-file=.env record.js <plugin-slug>.scenes.js --fast
```

- `--fast` records no video and removes pauses, so selector problems show up in seconds. Writing scenes still write in fast mode.
- Before the storyboard is approved, run only the read-only scenes, named with `--only` (comma-separated, no spaces).
- Run the full file only after approval.
- `--only` needs `--fast`, or `--out <dir>` for a partial recording, so a partial video never replaces the full one.

## 2. Failures

- Read the last log lines and `output/failure.png`. Each run deletes the previous `failure.png`, and secret-looking field values are blanked before it is taken.
- Fix the locator, or run `inspect-page.js` on that screen again.
- Add `--verbose` to see browser errors and stack traces. The browser console can contain the plugin's localized config, including nonces or keys. Use `--verbose` only when needed, and never quote secrets from it.
- Error messages and their fixes are listed in `scene-api.md` section 7.

## 3. Side-effect tally

After every run, including fast and failed runs, note what it wrote to the site.

- Count a write when the log shows the action that writes (for example `click Import selected`), even if a later step failed.
- Opening a post editor also writes: `post-new.php` saves an auto-draft, and `post.php?action=edit` sets an edit lock.
- When unsure, check the list screen where the result appears with `inspect-page.js`.

## 4. Recording and contact sheets

```sh
node --env-file=.env record.js <plugin-slug>.scenes.js --split
```

Build contact sheets only when the log ends with `saved output/...` lines and has no `FAILED` line. A recording run deletes the previous video, clips and contact sheets first, so a failed run leaves nothing stale to review.

```sh
node contact-sheet.js output/<plugin-slug>-demo.mp4 output/contact-sheet.png
node contact-sheet.js output/scenes/01-<scene>.mp4 output/sheet-01.png 2 2 960
```

The first sheet is a 3×3 overview. Per-scene sheets with 2×2 large tiles are needed to read text; small tiles are not enough to judge text or secrets. Check:

- The cursor is visible and each scene shows what the storyboard promised.
- Results and messages stay on screen long enough to read. Raise `demo.pause` or the scene file's `pace` if not.
- No unmasked secret is visible. Check the per-scene sheet of every scene that shows settings or credentials.
- The page fills the whole frame.

**Scenes marked "blur later" show an unmasked secret on purpose. Never build or read contact sheets of them.** The user reviews those clips.

Record again after changes, and add each run to the tally.

## 5. Report

Tell the user:

- Where the files are, as absolute paths: the full MP4, the scene clips, the contact sheets, `output/scenes.json`, and the scene file to record with again.
- The length and resolution, and what each scene shows.
- **Every change made to the site, from the tally**: the total over all runs, for example "3 draft posts titled X: 1 fast check, 1 failed run, 1 recording". Mention that each new run repeats them.
- Anything skipped and why, for example a field hidden by a plugin setting.
- Clips the user must review themselves (scenes marked "blur later").
- How to record again: `cd` to the workspace, then `node --env-file=.env record.js <plugin-slug>.scenes.js --split`.
