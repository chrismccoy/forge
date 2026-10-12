# Worked Example: YT Bulk Importer

A complete run of the workflow on a real plugin. YT Bulk Importer searches YouTube and imports videos as WordPress posts. The finished scene file is `example-yt-bulk-importer.scenes.js` in this folder.

## 1. Scanner output (shortened: long calls are cut with `...`)

```
== Plugin header (yt-bulk-importer.php)
  Plugin Name: YT Bulk Importer
  Text Domain: ytbi

== Admin pages (4)
  src/Admin/ImportPage.php:207  add_menu_page( __('YouTube Import', 'ytbi'), __('YT Importer', 'ytbi'), $capability, self::SLUG, ... )
  src/Admin/ImportPage.php:216  add_submenu_page( self::SLUG, __('YouTube Import', 'ytbi'), __('Import Videos', 'ytbi'), $capability, self::SLUG, ... )
  src/Admin/ImportPage.php:224  add_submenu_page( self::SLUG, __('Imported Videos', 'ytbi'), __('Imported Videos', 'ytbi'), $capability, self::listUrl() )
  src/Settings/Settings.php:312  add_submenu_page( ImportPage::SLUG, __('YT Bulk Importer Settings', 'ytbi'), __('Settings', 'ytbi'), ..., self::PAGE, ... )

== Settings (3)
  src/Settings/Settings.php:274  register_setting( 'ytbi', self::OPTION, ... )
  src/Settings/Settings.php:283  add_settings_section('ytbi_main', '', '__return_false', self::PAGE);
  src/Settings/Settings.php:286  add_settings_field( 'ytbi_' . $key, $field['label'], ..., 'label_for' => 'ytbi_' . $key, ... )

== REST routes (4)
  src/Rest/RestController.php:50  register_rest_route( self::NS, '/bootstrap', [ 'methods' => WP_REST_Server::READABLE, ... ] )
  src/Rest/RestController.php:60  register_rest_route( self::NS, '/search', [ 'methods' => WP_REST_Server::READABLE, ... ] )
  src/Rest/RestController.php:71  register_rest_route( self::NS, '/import', [ 'methods' => WP_REST_Server::CREATABLE, ... ] )
  src/Rest/RestController.php:91  register_rest_route( self::NS, '/test-key', [ 'methods' => WP_REST_Server::CREATABLE, ... ] )

== String constants (14, 3 shown)
  src/Admin/ImportPage.php:34  public const SLUG = 'ytbi-import';
  src/Settings/Settings.php:35  public const PAGE = 'ytbi-settings';
  src/Rest/RestController.php:35  public const NS = 'ytbi/v1';

== DOM hooks per file
  src/Settings/Settings.php  id=ytbi_test_key  id=ytbi_test_key_result ...
  views/import.php  data-state=idle  id=ytbi-q  id=ytbi-dialog  id=ytbi-results ...
  assets/js/import.js  .ytbi-card[data-state="done"]  .ytbi-desc  .ytbi-title  .ytbi-tags ...
```

## 2. What the analysis found

- **Slugs resolve through constants.** `self::SLUG` is `ytbi-import` and `self::PAGE` is `ytbi-settings`, so the screens are `admin.php?page=ytbi-import` and `admin.php?page=ytbi-settings`.
- **"Imported Videos" is a link, not a page.** Its slug comes from `self::listUrl()`, which returns `edit.php?post_type=<type>&ytbi_imported=1`. The demo reaches it by clicking the menu entry.
- **Settings fields use `label_for`**, so every field has a real `<label>`. The API key is rendered masked.
- **"Test key" is a read-only action.** It calls `POST /test-key` with the saved key and writes the result into `#ytbi_test_key_result`. It is a good demo moment, and nothing is saved.
- **The import screen is built in JS.** `views/import.php` renders the containers and a `<template id="ytbi-card">`. `import.js` fills `#ytbi-results` with `.ytbi-card` elements that carry `data-id` and `data-state` (`idle`, then `done` after import).
- **Search is disabled at first.** `import.js` sets `submitButton.disabled = locked || ! state.boot || ! state.boot.has_api_key`, so the button stays disabled until `GET /bootstrap` returns, and stays disabled without an API key. The scene waits for it to be enabled before typing.
- **`/import` writes.** It creates a post with the edited title and description, in the status set in the plugin settings (draft on the demo site). Each run creates one more post.
- **Optional fields.** The tags field in the edit dialog is hidden when "Import tags" is off in the settings. The scene guards it with `isVisible()`.

## 3. Questions asked and answers

1. Features: the settings page, a search, and editing one result before importing it.
2. Inputs: search for "funny dogs".
3. Should the import really run? Yes.
4. Secrets: the API key is already set and masked, so the settings page can be shown.
5. Presentation: plain screen capture, no captions or title cards.

## 4. Storyboard

```
Demo: YT Bulk Importer — about 55 seconds, 1920×1080

1. settings (~15s) — read-only, the key test uses a little YouTube API quota
   Start: admin.php?page=ytbi-settings
   Click "Test key" → wait for the result text → scroll through the fields. Nothing is saved.

2. search (~15s) — read-only, uses YouTube API quota
   Start: menu "Import Videos"
   Wait for Search to be enabled → type "funny dogs" → Search → wait for cards and thumbnails → scroll.

3. import (~25s) — WRITES: creates 1 post per run (draft on this site)
   Continues from: search
   Edit the first idle card → new title, description prefix, extra tag (if visible) → Done
   → Select → Import selected → wait for data-state="done" → point at "Edit post"
   → menu "Imported Videos" → point at the new post.
```

## 5. Result and lessons

The recording was 52 seconds. The contact sheet showed every scene as planned. A report following this workflow, with one fast check and one recording, tells the user:

- 2 draft posts titled "Funny Dogs Compilation – Edited Before Import" were created: 1 by the fast check and 1 by the recording. Each new run creates another.
- The tags step was skipped because "Import tags" was off in the settings.
- Admin text is small at 1920×1080. A 1280×720 viewport with `outputSize` 1920×1080 makes it larger.

Lessons that apply to other plugins:

- Pick items by state (`data-state="idle"`), not position. A card imported in an earlier run has its Edit button disabled, and `.first()` alone would stall the second run.
- Keep a locator by stable ID (`data-id`) after picking an item. A locator that filters on `data-state="idle"` stops matching once the state changes.
- Look for controls that start disabled. JS screens often wait for a startup request.
