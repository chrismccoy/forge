# Devices and browsers

## Default devices

Tablet: `Galaxy Tab S4`, 712×1138 CSS pixel viewport, DPR 2.25, Chromium. Its PNG is 1602×2561.

Mobile: `Pixel 7`: 412×839 CSS pixel viewport, DPR 2.625, touch and a mobile user agent. Its PNG is 1082×2202, because PNGs record device pixels, not CSS pixels.

## Browser per device

Each Playwright device descriptor has a default browser, and the CLI always uses it. The script looks it up in the pinned Playwright package before capturing, so this table is only a guide.

| Devices | Browser | First-use cost |
|---|---|---|
| `Pixel *`, `Galaxy S9+`, `Galaxy Tab S4` and other modern Android | Chromium | None when Google Chrome is installed; otherwise about 150 MB |
| `iPhone *`, `iPad *`, `Blackberry PlayBook`, `BlackBerry Z30`, `Galaxy S III`, `Galaxy Note II`, `Galaxy Note 3`, `Kindle Fire HDX`, `Nokia N9`, `Desktop Safari` | WebKit | About 100 MB, plus system libraries on Linux |
| `Desktop Firefox`, `Desktop Firefox HiDPI` | Firefox | About 110 MB |

Device names are case-sensitive. For every name and its default browser, see https://github.com/microsoft/playwright/blob/v1.64.1/packages/playwright-core/src/server/deviceDescriptorsSource.json.

## Linux system libraries

Bundled browsers may need system libraries on Linux:

```bash
sudo npx playwright@1.64.1 install-deps <chromium|webkit|firefox>
```

- WebKit almost always needs them. Minimal Linux images need them for Chromium too.
- The symptom is `Host system is missing dependencies` on stderr.
- The command uses `sudo`. Give it to the user to run, or get explicit approval first. If installing is not possible, switch to a Chromium device.
