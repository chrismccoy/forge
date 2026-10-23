## Perl rules

### Files and tools

- In scope: `.pm`, `.pl`, `.t`, `.psgi`, `.cgi`. The checker reads them with its own lexer (`lexers.mjs`): no tree-sitter grammar ships as wasm. The lexer knows POD blocks (`=head1` … `=cut`), `#` comments (not `$#array`), quoted strings, the quote-like operators (`q qq qw qr m s tr y` with any delimiter, including `s{…}{…}` and `m,…,`), regex versus division by context, heredocs (`<<"END"`, `<<~END`, `<<'END'`), file tests (`-s $file`), and `__END__` / `__DATA__` sections. It groups statements by `;` and by the `}` that closes a top-level `sub`, `package` or block.
- Out of scope: `blib/`, `local/`, `CPAN/` and other bundled third-party module trees, XS (`.xs`) and generated `.c`, `Makefile.PL` output, Template Toolkit / Mason templates (even when named `.js` or `.html`).
- Syntax check: `perl -c <file>` with the project's `-I` paths before and after (it compiles `BEGIN` blocks and `use` statements: run it only where loading the modules is safe). Baseline: `perlcritic` (no new violations; `Documentation::RequirePodSections` should go down), `podchecker <file>` (no new errors), `perltidy --assert-tidy` only if the project uses it. Tests: `prove -l t/`.

### Doc comment style

- POD for public API: a block before each public sub, or the module's POD after `__END__` (slimserver's style). Use the file's existing placement. A POD block starts with a command at the start of a line, with a blank line before and after it, and ends with `=cut` followed by a blank line:
  `=head2 add( $a, $b )` / blank / description / blank / `=cut`.
- `=head2 name` (or `=item name` inside `=over` / `=back`) names the sub; the coverage scan accepts that line anywhere in the file. Describe arguments in order (Perl has no signature types in most code: say which are hashrefs, arrayrefs, callbacks, and what keys a hashref takes), the return value in scalar and list context when they differ, and what dies (`die`, `croak`) or returns `undef`.
- Private helpers (`_name`) and small subs: `#` comment lines directly above `sub`.
- File header: the module POD (`=head1 NAME`, `Module::Name - summary`, then `=head1 SYNOPSIS` and `=head1 DESCRIPTION`), or `#` prose lines at the top, after the shebang and license. When a file starts with `package` and puts the license under it, put the header after both. Never break a `=cut`: removing one turns the following code into documentation, and adding one inside POD turns prose into code (the checker reports either as `CODE CHANGED`).

### Coverage

- Every top-level `sub`, documented by a `#` comment or POD block directly above it, or by a POD `=head` / `=item` line that names it anywhere in the file.
- Checked by reading: anonymous subs stored in dispatch tables (`my %handlers = ( play => sub { … } )`), callbacks passed to `Slim::Control::Request::addDispatch`, `AnyEvent` / `IO::Async` watchers, `subscribe` callbacks, `sort { … }` blocks that are not obvious.

### Comments that are code

- Frozen whole comment: shebangs, Perl::Critic `## no critic (…)` / `## use critic`, perltidy `#<<<` / `#>>>` skip markers, editor mode lines (`# -*- … -*-`, `# vim:`), Dist::Zilla / Pod::Weaver markers (`# PODNAME:`, `# ABSTRACT:`, `# VERSION`, `# AUTHORITY`: they generate POD or code), plus the shared license, copyright, `@generated` and `cspell:` forms.
- Kept lines: POD `=begin`, `=end`, `=for` (formatter- and tool-specific blocks such as `=for Pod::Coverage` and `=for stopwords`) and `=encoding`.
- `__END__` and `__DATA__` text is data, except POD blocks after `__END__`. Never add comments to it.

### Slimserver, Mojolicious, Dancer and Catalyst

- **Request dispatch:** `addDispatch([...], [...])` tables (Slim::Control::Request) form the command map: each command's terms, whether it is a query or a command, its parameters and its result keys.
- **Web routes:** Mojolicious `$r->get('/path')->to(...)`, Dancer `get '/path' => sub {…}`, Catalyst `:Path` / `:Local` attributes and Slim::Web::Pages handlers form the route map: method, path, auth, parameters, response.
- **Preferences:** `preferences('plugin.x')` keys are documented once where their defaults are set (`$prefs->init({...})`).
- **Events:** `Slim::Control::Request::subscribe` and `notify` commands follow the event map.
- **Environment:** `%ENV` reads form the env map.

### Bug report additions

- Two-argument `open` and `open` with unchecked results; string `eval` on input.
- Shell commands built from input (`system "cmd $arg"`, backticks) instead of the list form.
- Regexes built from input without `\Q…\E`; missing `use strict` / `use warnings`.
- `local $_` clobbering in callbacks; hashes iterated with `each` while modified.
