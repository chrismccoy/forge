/**
 * @file Scene file for the YT Bulk Importer plugin: settings tour, keyword search, edit one
 * result, import it, show it under Imported Videos. The import scene writes: it creates one
 * post on every run.
 *
 * Place it in the workspace next to record.js and run:
 *   node --env-file=.env record.js yt-bulk-importer.scenes.js --split
 */

const SEARCH_TERM = 'funny dogs';
const NEW_TITLE = 'Funny Dogs Compilation – Edited Before Import';
const EXTRA_TAG = 'funny dogs';

/** @type {import('./record.js').SceneConfig} */
export default {
  name: 'yt-bulk-importer-demo',
  viewport: { width: 1920, height: 1080 },
  scenes: [
    {
      name: 'settings',
      async run({ page, demo, log }) {
        await demo.open('admin.php?page=ytbi-settings');
        const heading = page.getByRole('heading', { name: 'YT Bulk Importer Settings' });
        await demo.waitFor(heading, 'settings heading');
        await demo.hover(heading, 'settings heading', 1500);

        // The saved key stays masked; the tester checks it without saving anything,
        // but the check calls the YouTube API and uses a little quota.
        // The button's text is translated, but its ID comes from the plugin source and never
        // changes, so the ID is the more stable locator here.
        await demo.click(page.locator('#ytbi_test_key'), 'Test API key');
        const result = page.locator('#ytbi_test_key_result').filter({ hasText: /\S/ });
        await demo.waitFor(result, 'key test result');
        log(`key test result: ${(await result.innerText()).trim()}`);
        await demo.pause(2000);

        await demo.scroll(450);
        await demo.pause(1200);
        await demo.scroll(600);
        await demo.pause(1500);
        await demo.scroll(-1200, 20);
      },
    },
    {
      name: 'search',
      async run({ page, demo, log }) {
        const menu = page.locator('#adminmenu').getByRole('link', { name: 'Import Videos' });
        await demo.click(menu, 'menu: Import Videos');
        await demo.waitFor(page.getByRole('heading', { name: 'YouTube Import' }), 'import heading');

        // Search stays disabled until the page's bootstrap request returns. `disabled: false`
        // makes the locator match only once the button is enabled.
        const searchButton = page
          .locator('#ytbi-search')
          .getByRole('button', { name: 'Search', disabled: false });
        await demo.waitFor(searchButton, 'Search to be enabled');
        await demo.pause(800);

        await demo.type(page.locator('#ytbi-q'), SEARCH_TERM, { label: 'search box' });
        await demo.click(searchButton, 'Search');
        const cards = page.locator('#ytbi-results .ytbi-card');
        await demo.waitFor(cards.first(), 'search results', { timeout: 30_000 });
        log('waiting for thumbnails to load');
        await page.waitForFunction(() =>
          [...document.querySelectorAll('#ytbi-results img')]
            .slice(0, 8)
            .every((img) => /** @type {HTMLImageElement} */ (img).complete),
        );
        log(`${await cards.count()} results shown`);
        await demo.pause(1500);

        await demo.scroll(500);
        await demo.pause(800);
        await demo.scroll(-500);
      },
    },
    {
      // Continues from "search": it uses the result cards on the current page.
      name: 'import',
      async run({ page, demo, log }) {
        // Results imported in an earlier run have Edit disabled, so pick an idle one.
        const card = page.locator('#ytbi-results .ytbi-card[data-state="idle"]').first();
        const videoId = await card.getAttribute('data-id');
        const target = page.locator(`#ytbi-results .ytbi-card[data-id="${videoId}"]`);
        log(`picked video ${videoId}`);

        await demo.click(target.getByRole('button', { name: 'Edit' }), 'Edit');
        const dialog = page.locator('#ytbi-dialog');
        await demo.waitFor(dialog, 'edit dialog');
        await demo.pause(2500);

        await demo.type(dialog.locator('.ytbi-title'), NEW_TITLE, {
          label: 'title field',
          replace: true,
          delay: 55,
        });

        const desc = dialog.locator('.ytbi-desc');
        if (await desc.isVisible()) {
          await demo.click(desc, 'description field');
          await desc.press('ControlOrMeta+Home');
          log('prefix description');
          await desc.pressSequentially('Imported with YT Bulk Importer.\n\n', { delay: 45 });
          await demo.pause(800);
        } else {
          log('description field hidden, skipped');
        }

        // Hidden when "Import tags" is off in the plugin settings.
        const tags = dialog.locator('.ytbi-tags');
        if (await tags.isVisible()) {
          await demo.click(tags, 'tags field');
          await tags.press('End');
          const current = await tags.inputValue();
          log(`add tag "${EXTRA_TAG}"`);
          await tags.pressSequentially(current.trim() ? `, ${EXTRA_TAG}` : EXTRA_TAG, {
            delay: 60,
          });
          await demo.pause(800);
        } else {
          log('tags field hidden, skipped');
        }

        await demo.click(dialog.getByRole('button', { name: 'Done' }), 'Done');
        await demo.waitFor(dialog, 'edit dialog to close', { state: 'hidden' });
        await demo.waitFor(
          target.locator('.ytbi-card-title').filter({ hasText: NEW_TITLE }),
          'new title on the card',
        );
        await demo.pause(1200);

        await demo.click(target.getByLabel('Select'), 'Select');
        await demo.pause(600);
        await demo.click(page.getByRole('button', { name: 'Import selected' }), 'Import selected');
        await demo.waitFor(target.and(page.locator('[data-state="done"]')), 'import to finish', {
          timeout: 60_000,
        });
        log('import done');
        await demo.hover(target.getByRole('link', { name: 'Edit post' }), 'Edit post link', 2500);

        const importedMenu = page
          .locator('#adminmenu')
          .getByRole('link', { name: 'Imported Videos' });
        await demo.click(importedMenu, 'menu: Imported Videos');
        const post = page.getByRole('link', { name: NEW_TITLE }).first();
        await demo.waitFor(post, 'imported post in list');
        await demo.hover(post, 'imported post', 3000);
      },
    },
  ],
};
