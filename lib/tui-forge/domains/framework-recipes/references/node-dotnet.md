# Node, TypeScript, and .NET Framework Recipes

## Node and TypeScript

### Ink component, resize, and testing pattern

Ink brings React component architecture to terminals. It is a strong fit when teams already use React patterns and want component tests. Avoid expensive render-side effects and test with fixed terminal dimensions.

This version-agnostic component runs on Ink 4 through 8. It tracks width from `useStdout()` resize events:

```tsx
import React, {useEffect, useState} from 'react';
import {Box, Text, useApp, useInput, useStdout} from 'ink';

// onExit runs for q (code 0) and Ctrl-C (code 130) only. Render with `exitOnCtrlC: false`
// (see the entry point below): with the default `true`, Ink exits on Ctrl-C itself and
// useInput never sees it. `notice` shows the last editor failure; `handOff` opens a file.
type AppProps = {
  load: () => Promise<string[]>;
  onExit?: (code: number) => void;
  handOff?: (file: string) => Promise<void>;
  notice?: string | null;
};

export function App({load, onExit, handOff, notice}: AppProps) {
  const {exit} = useApp();
  // Ink 8 types useStdout().stdout as NodeJS.WritableStream (no `columns`); at run time it
  // is still the tty WriteStream, so the cast keeps one source for Ink 4-8.
  const out = useStdout().stdout as NodeJS.WriteStream;
  const [columns, setColumns] = useState(out.columns ?? 80);
  const [items, setItems] = useState<string[]>([]);

  useInput((input, key) => {
    if (input === 'q' || (key.ctrl && input === 'c')) {
      onExit?.(input === 'q' ? 0 : 130);
      exit();
    }
    if (input === 'e') void handOff?.('notes.txt'); // see the entry point
  });

  useEffect(() => {
    let alive = true;
    load().then(value => { if (alive) setItems(value); });
    return () => { alive = false; };
  }, [load]);

  useEffect(() => {
    const onResize = () => setColumns(out.columns ?? 80);
    out.on('resize', onResize);
    return () => { out.off('resize', onResize); };
  }, [out]);

  if (columns < 40) return <Text>Terminal too narrow. Press q to quit.</Text>;
  return (
    <Box flexDirection="column">
      {notice ? <Text color="red">{notice}</Text> : null}
      <Text bold>Items</Text>
      {items.map(i => <Text key={i}>- {i}</Text>)}
    </Box>
  );
}
```

Optional upgrade on Ink 7.0+: replace the cast, the `columns` state, and the resize effect with `const {columns} = useWindowSize();` (imported from `ink`), which re-renders on resize. `useWindowSize` does not exist on Ink 6 or earlier. Code that reads `useStdout().stdout.columns` without the cast fails to typecheck on Ink 8. Check the installed version with `npm ls ink`.

Entry point. Ink restores the terminal on SIGTERM/SIGHUP/SIGINT by itself, but the app's `onExit` cleanup does not run there, so hook those signals too. An external `kill -INT` arrives as a real SIGINT; the Ctrl-C key arrives as input and goes through `onExit(130)`. Closing the terminal window often never runs the SIGHUP listener: stdin ends first, the event loop drains, and the process would exit 0. The `exit` hook and the stdin `end` handler cover that case.

`handOff` gives the terminal to `$VISUAL`/`$EDITOR`. Two details matter:

- The editor variable is a shell command (`code --wait`, `emacsclient -t`), so run it through `sh -c 'exec …'`. Spawning it directly fails with ENOENT. Report spawn errors and nonzero exits in the UI.
- Ctrl-C or Ctrl-\ typed into the child also reaches this process (same foreground process group). Ignore SIGINT/SIGQUIT while the child runs, as `system(3)` does. Node delivers those queued signals only after `spawnSync` returns, so yield two event-loop turns (two `setImmediate` passes) before clearing the flag.

```tsx
import React from 'react';
import {spawnSync} from 'node:child_process';
import {constants} from 'node:os';
import {render} from 'ink';
import {App} from './app.js';
import {load} from './data.js';

let cleanedUp = false;
function cleanup(): void {
  if (cleanedUp) return; // idempotent: may run from onExit, a signal, and 'exit'
  cleanedUp = true;
  // Flush logs, remove temp files, release locks (synchronous work only in 'exit').
}

function onExit(code: number): void {
  cleanup();
  process.exitCode = code; // 130 for Ctrl-C, matching the shell convention
}

let inChild = false;          // true while the editor owns the terminal
let notice: string | null = null; // last editor failure, shown after remount

function runEditor(file: string): string | null {
  const editor = process.env.VISUAL || process.env.EDITOR || 'vi';
  const result = process.platform === 'win32'
    ? spawnSync(`${editor} "${file}"`, {stdio: 'inherit', shell: true})
    // `exec`: some sh (dash) otherwise fork, and a shell killed by Ctrl-\ can leave the editor
    // running, still fighting the remounted app for the terminal.
    : spawnSync('sh', ['-c', `exec ${editor} "$1"`, 'sh', file], {stdio: 'inherit'});
  if (result.error) return `${editor}: ${result.error.message}`;
  if (result.signal) return `${editor} killed by ${result.signal}`;
  if (result.status !== 0) return `${editor} exited with status ${result.status}`;
  return null;
}

// handOff reassigns `app`, so the signal handlers below unmount the live instance,
// not the one torn down for the child.
async function handOff(file: string): Promise<void> {
  inChild = true; // before teardown: once raw mode is off, a Ctrl-C typed for the child raises SIGINT
  try {
    const exited = app.waitUntilExit(); // get it first: Ink 4 creates it lazily, so after unmount it never settles
    app.unmount();                       // restores raw mode and the cursor
    await exited;
    notice = runEditor(file);
    // SIGINT/SIGQUIT from the child's Ctrl-C/Ctrl-\ are queued; two check phases let their
    // listeners run (and be ignored) before the flag clears. One is not always enough.
    for (let i = 0; i < 2; i++) await new Promise(resolve => setImmediate(resolve));
  } finally {
    inChild = false; // cleared on every path, including a rejected waitUntilExit()
  }
  app = mount();
}

const mount = () =>
  render(<App load={load} onExit={onExit} handOff={handOff} notice={notice} />, {exitOnCtrlC: false});
let app = mount();
const signals: NodeJS.Signals[] = ['SIGTERM', 'SIGHUP', 'SIGINT'];
if (process.platform !== 'win32') signals.push('SIGQUIT'); // Windows never delivers SIGQUIT to a listener (libuv emulates only SIGINT, SIGBREAK, SIGHUP and SIGWINCH)
for (const sig of signals) {
  process.on(sig, () => {
    if ((sig === 'SIGINT' || sig === 'SIGQUIT') && inChild) return; // the child's key, not ours
    cleanup();
    app.unmount(); // restores raw mode and the cursor; safe to repeat
    process.exit(128 + constants.signals[sig]);
  });
}
// Real hangup: stdin ends before any SIGHUP listener runs. Report 129 and still clean up.
process.stdin.once('end', () => { process.exitCode ??= 128 + constants.signals.SIGHUP; });
process.once('exit', cleanup);
// Hangup during the editor: the remount's first write, or a stdin read, can fail with EIO before SIGHUP arrives.
// Listen on all three streams (Ink 4 writes to stderr first; a stdin EIO races SIGHUP, seen on Ink 6.8 and 8.0);
// otherwise node dies on an uncaught error with exit 1. Only EIO means hangup; any other stream error
// (EPIPE when stdout is a closed pipe) exits 1.
for (const s of [process.stdin, process.stdout, process.stderr]) {
  s.on('error', err => { cleanup(); process.exit(err?.code === 'EIO' ? 128 + constants.signals.SIGHUP : 1); });
}
```

Newer Ink (reported from 7.1; present in 8.0, absent in 6.8) adds `useApp().suspendTerminal(async () => { … })` as a built-in alternative to unmount and remount. The `sh -c 'exec …'` and `inChild` rules still apply inside the callback.

On Windows, Node emits SIGHUP when the console window closes and never emits SIGTERM from `kill`; SIGQUIT never reaches a listener. The `shell: true` form passes the command line to `cmd.exe`, so keep `file` a trusted path.

Test shape for Jest, or Vitest with `globals: true` (or import `test` and `expect` from 'vitest'). Use ink-testing-library 4 or newer; 3.x fails on Ink 4/5 with `stdin.ref is not a function`:

```tsx
import React from 'react';
import {render} from 'ink-testing-library';
import {App} from './app.js';

// Poll instead of a fixed setTimeout(0): async loaders may need several ticks.
async function waitFor(check: () => boolean, timeoutMs = 1000): Promise<void> {
  const start = Date.now();
  while (!check()) {
    if (Date.now() - start > timeoutMs) throw new Error('waitFor timed out');
    await new Promise(resolve => setTimeout(resolve, 10));
  }
}

test('renders loaded items', async () => {
  const {lastFrame, stdin, unmount} = render(<App load={async () => ['alpha']} />);
  await waitFor(() => (lastFrame() ?? '').includes('alpha'));
  expect(lastFrame()).toContain('alpha');
  stdin.write('q');
  unmount();
});
```

Guidelines:

- Use fixed stdout dimensions in tests when layout matters.
- Mock async loaders, timers, and clocks.
- Avoid writing directly to stdout/stderr from components; let Ink own rendering.
- Prefer prompt libraries for short questionnaires; use Ink when stateful screens and React composition pay for themselves.

### Blessed and prompt libraries

Blessed provides a screen and widget tree with manual lifecycle control. For maintenance status, see `domains/tui-fundamentals/references/framework-selection.md`. When maintaining an existing Blessed app, verify terminal compatibility, mouse behavior, resize handling, and Windows behavior. Always call screen cleanup on `q`, Ctrl-C, exceptions, and rejected async work.

Prompt libraries are the right choice for short forms and setup wizards. Common choices: `@inquirer/prompts` (the current Inquirer API), `@clack/prompts`, `prompts`, and `enquirer`; check release activity and open issues before adopting one. Do not build a full-screen app when a sequence of accessible prompts is enough. Ensure prompts accept non-interactive equivalents through flags, config, stdin, or environment variables.

## .NET

Terminal.Gui is appropriate for full-screen keyboard-first applications with views, dialogs, layout, and mouse support. Keep view model logic testable outside terminal rendering, and guarantee shutdown (v1: `Application.Shutdown()` in `finally`; v2: dispose or shut down the application instance in `finally`/`using`) or use host lifetime management. Terminal.Gui v2 uses an instance-based model (per current v2 docs as of 2026-11, recheck: `Application.Create()`, `app.Init()`, `app.Run(window)`); v1 used static `Application.Init()` / `Application.Shutdown()`. The APIs are not source-compatible: pin the major version, check current docs, and follow the official v1-to-v2 migration guide when upgrading.

Spectre.Console is appropriate for polished CLI output: prompts, tables, trees, progress, status, markup, and command apps. It is often the accessibility and automation friendlier choice. Use `AnsiConsole.Profile.Width` or test consoles with fixed width for snapshots.

## Framework selection

Framework maintenance checks, the pre-commit spike, and selection gotchas live in `domains/tui-fundamentals/references/framework-selection.md`.
