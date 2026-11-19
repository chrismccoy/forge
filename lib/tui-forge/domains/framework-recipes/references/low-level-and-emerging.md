# Low-Level, C/C++, Zig, Swift, and Emerging Frameworks

## C and C++

### ncurses

Use ncurses when portability through terminfo, classic widgets, panels, forms, menus, windows, pads, and mature Unix deployment matter. It abstracts many terminal capabilities but requires careful mode setup, resize handling, color-pair management, and cleanup.

Safe wrapper shape:

```c
#define _POSIX_C_SOURCE 200809L  /* sigaction/struct sigaction under -std=c11/c99 */
#include <locale.h>
#include <ncurses.h>
#include <signal.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static bool curses_started = false;
static volatile sig_atomic_t stop_requested = 0;
static bool stdin_tty = false;   /* stdin was a terminal at startup */

static void on_signal(int sig) { stop_requested = sig; } /* async-signal-safe: set a flag only */

void tui_stop(void) {
    if (!curses_started) return;   /* idempotent: safe from atexit and normal exit */
    curs_set(1);
    nocbreak(); echo();
    endwin();
    curses_started = false;
}

void tui_start(void) {
    /* Install handlers before initscr(): no unprotected startup window, and
       ncurses keeps handlers the app already set instead of adding its own. */
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_signal;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);  /* terminal closed */
    sigaction(SIGQUIT, &sa, NULL); /* Ctrl-\: cbreak keeps ISIG on */

    stdin_tty = isatty(STDIN_FILENO);
    setlocale(LC_ALL, "");
    initscr(); curses_started = true;
    atexit(tui_stop);              /* covers exit() from any path */
    cbreak(); noecho(); keypad(stdscr, TRUE);
    timeout(100);                  /* getch returns ERR every 100 ms so the loop can see stop_requested */
    curs_set(0);
    if (has_colors()) { start_color(); use_default_colors(); }
}

int main(void) {
    tui_start();
    erase(); mvaddstr(0, 0, "Press q to quit"); refresh();  /* initial draw */
    while (!stop_requested) {
        int ch = getch();
        if (ch == ERR) {
            /* A hung-up tty returns ERR at once, not after 100 ms. If SIGHUP never
               arrives (the session leader ignores or does not forward it), treat it as one. */
            if (stdin_tty && !isatty(STDIN_FILENO)) { stop_requested = SIGHUP; break; }
            continue;              /* timeout: nothing changed, do not redraw while idle */
        }
        if (ch == 'q') break;
        if (ch == KEY_RESIZE) { /* recompute layout from getmaxyx */ }
        erase(); mvaddstr(0, 0, "Press q to quit"); refresh();  /* redraw only on input or resize */
    }
    tui_stop();
    if (stop_requested) {
        /* Re-raise with the default action so the parent sees WIFSIGNALED
           (shell loops stop; $? is still 130/143/129/131). */
        signal(stop_requested, SIG_DFL);
        raise(stop_requested);
    }
    return 0;
}
```

The wrapper restores the terminal on `q`, on SIGINT/SIGTERM/SIGHUP/SIGQUIT (handlers are installed before `initscr()` and only set a flag; drawing or calling `endwin()` inside a handler is unsafe; after cleanup the signal is re-raised with its default action so callers see a signal death), and on any `exit()` via `atexit`. The loop redraws only on input or `KEY_RESIZE`, never on the idle 100 ms timeout. If the terminal closes and SIGHUP never arrives, `getch()` returns ERR at once; the `isatty` check turns that into the SIGHUP path instead of a busy loop. With `cbreak()`, Ctrl-C and Ctrl-\ still raise SIGINT and SIGQUIT (the re-raised SIGQUIT may dump core); with `raw()` Ctrl-C arrives as byte 3 and must be handled as a key. Fatal signals such as SIGSEGV bypass `atexit`; document the canonical recovery line ("Recovery commands for users" in `domains/tui-troubleshooting/GUIDE.md`) for users.

Common pitfalls: assuming coordinates are x,y rather than y,x, leaking raw/cbreak/noecho mode after crashes, treating bytes as characters, relying on a specific curses color-pair limit, and expecting modern truecolor or mouse behavior without validating the target curses build.

### notcurses

Use notcurses when modern terminal graphics, rich cells, visual effects, images/video where supported, and high-performance rendering are product goals. Provide degradation for terminals without the needed graphics protocols and test inside multiplexers. Treat advanced visuals as enhancements, not the only way to read state.

### FTXUI

Use FTXUI for composable C++ terminal components, layout, and event handling. Keep business state outside component rendering and test resize, Unicode, mouse, and alternate-screen cleanup in the exact deployment terminals. Verify Windows console behavior and packaging expectations for the target compiler and runtime.

## Low-level framework cautions

Choosing a low-level cell or ANSI library means the app owns product behavior that high-level frameworks normally provide:

- Terminal mode guard with idempotent cleanup.
- Frame buffer, diffing, batching, and resize invalidation.
- Unicode grapheme and width measurement.
- Focus traversal, widget state, validation, and help text.
- Mouse, paste, Esc/Alt ambiguity, and keybinding configuration.
- Color fallback, `NO_COLOR`, `TERM=dumb`, non-TTY handling.
- PTY/virtual terminal tests and Windows ConPTY tests.
- Escape injection prevention for untrusted data.

Use direct ANSI only for tiny controlled surfaces such as a simple progress region, and still gate it behind TTY detection. For product TUIs, prefer a maintained library unless the UI itself is the differentiator.

## Zig

zig-vaxis (libvaxis, `rockorager/libvaxis`) is a modern Zig terminal UI toolkit. It is distinct from the Go `vaxis` library by the same author; this section covers the Zig one only. libvaxis is focused on robust terminal handling. It is attractive for single-binary distribution and low-level control. Validate Unicode width behavior, Windows support expectations, and terminfo/protocol behavior before choosing it for broad consumer use. Build an early compatibility spike for paste, resize, terminal cleanup, and tmux/SSH behavior.

## Swift

SwiftTUI-style frameworks fit teams building Swift-native command-line tools. Confirm Linux/macOS support, terminal mode cleanup, package distribution, and CI testing strategy. For simple rich output, a lighter CLI output library may be more appropriate than a full-screen app.

## Emerging and niche toolkit checklist

Before adopting a less common toolkit, answer:

- Is it maintained and documented?
- Does it support raw mode cleanup, resize, mouse, paste, and Unicode width correctly?
- Does it have snapshot or PTY testing examples?
- Does it work on Windows, macOS, Linux, tmux, SSH, and the target terminals?
- Can it degrade to no-color, ASCII, non-TTY, and no-mouse modes?
- Are packaging and licensing acceptable?
- Does the maintainer recommend production use, or is it experimental?
- Can the team debug raw byte captures when something breaks?

If any answer is unknown, build a spike with resize, Unicode, paste, mouse, crash cleanup, and non-TTY tests before committing.
