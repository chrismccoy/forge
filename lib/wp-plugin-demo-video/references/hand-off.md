# Hand-off Mode

Used when this environment cannot record: no Node.js, a browser that cannot start, or no network access to the site (for example a cloud sandbox and a local or private site). Tell the user which check failed, then follow these steps. The user runs the commands; Claude writes the scene file, reads the results and keeps the tally.

1. **No login here.** Do not ask for the login. If the user already put it in a `.env` here, tell them to delete that file.
2. **Workspace.** If step 2 did not create it, create the folder now, copy `"<skill dir>/scripts/."` into it and write the `.gitignore` (`setup.md` section 3). Do not run npm.
3. **Analysis.** Analyse the source (step 3). Without Node.js, skip the scanner and search the source with the available tools for the patterns in `plugin-analysis.md` section 1.
4. **Storyboard and scene file.** Skip the live check. In the storyboard, mark every selector that comes only from the source as unverified. Then do steps 5 and 6.
5. **Delivery.** Deliver the workspace as a zip file the user can download: the scripts, `package.json`, `package-lock.json`, `.env.example`, the scene file and the `.gitignore`. Leave out `node_modules/`, `output/` and any `.env`. Tell the user to unzip it outside the plugin directory and outside any web root, such as `~/wp-demo-videos/<plugin-slug>-demo`.
6. **Round 1: setup and read-only check.** Give the user these commands. Ask them to stop after the last one and send back all console output plus the `output/inspect/` files (`.png` and `.aria.yml`):

   ```sh
   cd "$HOME/wp-demo-videos/<plugin-slug>-demo"
   node -v                                  # must be 20.6 or later
   npm install
   npx playwright install chromium
   printf "WP_URL='https://staging.example.com'\n" > .env && chmod 600 .env   # use the real site URL
   node --env-file=.env check-env.js --site
   # add WP_USER and WP_PASS to .env, then:
   node --env-file=.env check-env.js
   node --env-file=.env inspect-page.js --menu 'plugins.php' 'admin.php?page=<page-slug>'
   node --env-file=.env record.js <plugin-slug>.scenes.js --fast --only <read-only scenes>
   ```

   Fix the scene file from what they send, deliver it again, and repeat until the read-only scenes pass. Use `setup.md` section 5 to explain any failed check.
7. **Round 2: full check.** After the storyboard is approved, and after pointing out which scenes write data: `node --env-file=.env record.js <plugin-slug>.scenes.js --fast`. Ask for the console output.
8. **Round 3: recording.** Give these commands, with one per-scene sheet line for every scene that is not marked "blur later":

   ```sh
   node --env-file=.env record.js <plugin-slug>.scenes.js --split
   node contact-sheet.js output/<plugin-slug>-demo.mp4 output/contact-sheet.png
   node contact-sheet.js output/scenes/01-<scene>.mp4 output/sheet-01.png 2 2 960
   ```

   Ask for the console output and the sheets.
9. **Tally, review and report.** Keep the tally from every log the user sends, review their sheets, and finish with the report (`review.md` sections 3 to 5).
