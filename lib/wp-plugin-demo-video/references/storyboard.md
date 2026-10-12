# Storyboard

How to turn a feature map into a scene plan that the user approves before anything is recorded.

## Questions to ask the user

Ask these in one message, after the feature map is ready. Skip any question the user has already answered.

1. **Which features to show.** Offer the screens from the feature map and suggest an order.
2. **Inputs to type.** Search terms, names, sample text. Real inputs make a better demo than "test".
3. **Actions that write data.** For each "creates content" or "destructive" action in the plan: should it really run? Explain what it will create or change on the site. Suggest a staging site or a temporary admin account.
4. **Secrets on screen.** For every unmasked secret, choose one:
   - **Use a demo value** (recommended): a fake or revocable key on the staging site.
   - **Skip** that part of the screen.
   - **Blur it later** in a video editor. The secret is then recorded in clear, so mark that scene "blur later" in the storyboard. Claude never builds or reads contact sheets of it; the user reviews it.
5. **Presentation.** Plain screen capture is the default (no captions, title cards or audio). Ask about the target length and whether the admin text should be larger (see "Size and readability").

## Scene design rules

- **3 to 6 scenes, 10 to 40 seconds each.** One scene shows one idea: "configure", "search", "edit and import", "see the result".
- **Name scenes in lower case with one word or a short kebab-case name** (`settings`, `search`, `import`). The names appear in the log and in the clip file names (`01-settings.mp4`).
- **Start each scene from a known URL** with `demo.open(...)`, unless it continues the previous scene on purpose. A scene that continues must say so in the storyboard, because `--only` cannot run it alone.
- **Navigate through the admin menu when it helps the story.** Clicking "Import Videos" in the menu shows viewers where the feature lives. Use `demo.open` when the route is not interesting.
- **Show the result of every action.** After a click that does something, wait for the visible change (message, new card state, updated title) and pause on it for 1.5 to 3 seconds.
- **Keep login out of the video.** `record.js` logs in before recording starts.
- **End on the outcome.** The last scene should show what the plugin produced: the created post, the list entry, the front-end output.
- **Pacing.** The helpers already add short pauses. Add `demo.pause(1500)` to `demo.pause(3000)` after page loads and results, so viewers can read. Scroll in steps of 400 to 600 px.

## Side effects in the plan

Mark every scene with its side effects. Report them in the final summary.

- **Read-only** scenes can be re-run freely.
- **Writing** scenes create data on each run. Prefer to test them last, after the read-only scenes pass with `--fast`.
- **Approval means at least two runs.** Tell the user: a writing scene runs once in the fast check and once in the recording. Failed runs and re-recordings add more. Every run is counted in the side-effect tally (`review.md` section 3).
- **Order matters** when one scene uses the result of another. Note the dependency.

## Size and readability

WordPress admin text is small in a 1920×1080 video. Two options in the scene file:

| Setting | Effect |
| --- | --- |
| `viewport: { width: 1920, height: 1080 }` (default) | Sharp, but small text. Good for full-screen viewing. |
| `viewport: { width: 1280, height: 720 }, outputSize: { width: 1920, height: 1080 }` | Larger text: the page is laid out at 1280×720 and upscaled. Slightly softer. Good for embedded players and social media. |

Do not use `deviceScaleFactor` for this. Playwright records the video at the CSS viewport size and pads the rest, so the picture fills only part of the frame.

## Storyboard template

Show this to the user and wait for approval.

```
Demo: <plugin name> — about <N> seconds, <viewport> → <output size>

1. settings (~15s) — read-only
   Start: admin.php?page=<page-slug>
   Click "Test key" → wait for "<result text>" → scroll through the fields. Nothing is saved.

2. search (~20s) — read-only, external API call (uses quota)
   Start: menu "Import Videos"
   Type "<term>" → Search → wait for result cards → scroll the results.

3. import (~25s) — WRITES: creates 1 draft post per run
   Continues from: search
   Edit first unused result → change title to "<title>" → Done → Select → Import selected
   → wait for "Imported" → open "Imported Videos" and point at the new post.

Skipped: <features left out and why>
Needs approval: scene 3 creates a post each time it runs.
```
