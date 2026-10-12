# Setup

Step 2 in detail: workspace, dependencies, `.env` and the environment check. Commands are for Linux and macOS shells (bash, zsh); on Windows, use WSL.

## Contents

1. Quoting
2. Untrusted zip files
3. Workspace and dependencies
4. `.env` in two stages
5. Environment check and failures

## 1. Quoting

- Single-quote admin paths: `'admin.php?page=<page-slug>'`. Unquoted, `?` fails in zsh ("no matches found") and `&` sends the command to the background in every shell.
- Double-quote file paths: `"<plugin dir>"`, `"<skill dir>"`. They can contain spaces; LocalWP uses `~/Local Sites/...`.
- `~` does not expand inside quotes. Write `$HOME` instead.

## 2. Untrusted zip files

1. List the entries first: `unzip -l "<zip>"`.
2. Refuse the zip if any entry path is absolute or contains `..`.
3. Extract it into its own new, empty directory, outside the workspace.
4. Treat symlinks in the extracted tree as untrusted: do not follow them when reading files. `scan-plugin.js` skips them.

## 3. Workspace and dependencies

Run `node -v` first. Node.js 20.6 or later is needed, the first version with `--env-file`. If it is missing or older, ask the user to install or update it, or switch to hand-off mode (`hand-off.md`).

The workspace is `$HOME/wp-demo-videos/<plugin-slug>-demo` unless the user picks another place. Never put it inside the plugin directory or inside a web root (any path containing `wp-content`, `public_html`, `htdocs`, `www` or `app/public`): `.env` holds the admin password, and a web server can serve it.

```sh
mkdir -p "$HOME/wp-demo-videos/<plugin-slug>-demo"
cp -r "<skill dir>/scripts/." "$HOME/wp-demo-videos/<plugin-slug>-demo/"
cd "$HOME/wp-demo-videos/<plugin-slug>-demo"
npm install
npx playwright install chromium
printf '.env\nnode_modules/\noutput/\n' > .gitignore
```

The copy includes `package-lock.json` (exact versions) and `.env.example` (the `.env` template). Tell the user the workspace's absolute path.

## 4. `.env` in two stages

Never read or print `.env`. Tell the user never to paste the password into the chat.

**Stage 1.** Ask the user to create `.env` with only the site URL:

```sh
WP_URL='https://staging.example.com'
```

```sh
chmod 600 .env
```

Run `node --env-file=.env check-env.js --site`.

**Stage 2.** When every line shows `ok`, ask the user to add the login to the same file:

```sh
WP_USER='demo-admin'
WP_PASS='...'
```

Then run `node --env-file=.env check-env.js`.

Values go in single quotes. Unquoted, Node.js cuts a value at `#` and drops trailing spaces, so a password such as `pa#ss` arrives as `pa` and login fails with "incorrect password".

Optional keys, only when a check asks for them: `WP_LOGIN_PATH`, `WP_HTTP_USER`, `WP_HTTP_PASS`, `WP_IGNORE_HTTPS_ERRORS=1`. They are described in `scene-api.md` section 6.

## 5. Environment check and failures

Continue only when every line shows `ok`. A `note` line does not fail the run.

| Failure | Action |
| --- | --- |
| `node: .env: not found` | `.env` is missing or in another directory. Give the user the workspace path again. |
| `bad option: --env-file=.env` | Node.js is older than 20.6. Ask the user to update it, or switch to hand-off mode. |
| `.env` missing keys | Ask the user to add them. |
| `note .env readable by other users` | Ask the user to run `chmod 600 .env`. |
| `ffmpeg` | Run `npm install` again. Check that npm scripts are not disabled (`ignore-scripts`). |
| `chromium` | Ask the user to run `npx playwright install --with-deps chromium`; it installs system libraries and can ask for sudo. If Chromium still fails, switch to hand-off mode. |
| `site` certificate error | A local dev site with a self-signed certificate. Ask the user to add `WP_IGNORE_HTTPS_ERRORS=1`. |
| `site` HTTP 401 | HTTP basic auth. Ask the user to add `WP_HTTP_USER` and `WP_HTTP_PASS`. |
| `site` HTTP 404 | A custom login URL. Ask the user for its path and to add `WP_LOGIN_PATH` (for example `'my-login'`). |
| `site` HTTP 403 or other status | A firewall, security plugin or server problem. Report the status and ask the user. |
| `site` unreachable | This machine cannot reach the site. Switch to hand-off mode. |
| `login` `Login failed: ...incorrect` | Wrong password. Ask the user to fix `WP_PASS` in `.env` (single quotes). |
| `login` `Login failed: ...not registered` | Unknown user name. Ask the user to fix `WP_USER` in `.env`. |
| `login` `Login failed (no redirect to /wp-admin/)` or `login form not found` | Two-factor authentication, a CAPTCHA or a custom login page. Ask for a demo account without 2FA, or for `WP_LOGIN_PATH`. |
| `login` `Administration email verification` | Ask the user to log in once in a browser and confirm the email. Never confirm it yourself. |
