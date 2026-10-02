# PERL facts
Covers: Perl 5 (5.44 current) CLIs with Getopt::Long, cron batch jobs, DBI, Template Toolkit, self-hosted deployment (perlbrew/plenv, Carton)
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Database (DBI)

### PL-01 DBI autocommits and only warns on errors by default
- Trap: A batch import runs "in a transaction" and stops on the first failed statement because it uses DBI.
- Reality: `AutoCommit` and `PrintError` default to on, and `RaiseError` defaults to off. Each statement commits immediately, and a failed statement only `warn`s while the script carries on. DBI strongly recommends setting `AutoCommit` explicitly. `begin_work` turns it off until the next `commit` or `rollback`.
- Detect: `DBI->connect($dsn, $u, $p)` with no attribute hash; "all-or-nothing load" with no `begin_work`/`AutoCommit => 0`; no `eval`/`Try::Tiny` around the work.
- Fix: `DBI->connect(..., { RaiseError => 1, PrintError => 0, AutoCommit => 1 })`, and wrap multi-statement units in `begin_work` ... `commit`, with `rollback` on error.
- Source: DBI - https://metacpan.org/pod/DBI

### PL-02 Handles must not cross fork, and values belong in placeholders
- Trap: The parent opens `$dbh`, forks workers that inherit it, and SQL is built with interpolated values or `$dbh->quote`.
- Reality: For some drivers, a child exiting destroys inherited handles and breaks the parent's connection. DBI recommends `AutoInactiveDestroy` on all new code (off by default for compatibility). `quote()` may not handle all input (binary, newlines) and must not be mixed with placeholders.
- Detect: `fork`, Parallel::ForkManager or preforking daemons with a connection opened before the fork; `"... WHERE id = $id"` in SQL strings.
- Fix: Connect with `AutoInactiveDestroy => 1` and open a new connection in each child. Pass all values as `?` placeholders.
- Source: DBI, InactiveDestroy/AutoInactiveDestroy and Placeholders and Bind Values - https://metacpan.org/pod/DBI

## Templates and output

### PL-03 Template Toolkit does not escape HTML
- Trap: `[% user.name %]` in a TT page is safe from XSS, like auto-escaping template engines.
- Reality: TT2 core interpolates raw values and has no auto-escape configuration option. Escaping needs the `html` filter (`[% user.name | html %]`), which converts `<`, `>`, `&` and `"`. Template::AutoFilter is a separate, self-described experimental CPAN module that adds a default filter.
- Detect: TT views rendering user or device data without `| html` (or `| uri` in URLs), a security section that assumes templates escape.
- Fix: Filter every interpolation for its context (`| html`, `| uri`) and enforce it in review, or adopt a subclass such as Template::AutoFilter after evaluating it.
- Source: Template::Manual::Filters - https://metacpan.org/pod/Template::Manual::Filters ; Template::Manual::Config - https://metacpan.org/pod/Template::Manual::Config

### PL-04 `use utf8` does not decode input or encode output
- Trap: Adding `use utf8` makes the script handle UTF-8 files, database rows and STDOUT correctly.
- Reality: `use utf8` only declares that the source code is UTF-8. I/O needs layers: `open my $fh, '<:encoding(UTF-8)', $f`, `binmode(STDOUT, ':encoding(UTF-8)')`, or the `open` pragma. Printing characters above 255 to a handle without a layer gives "Wide character in print". `:utf8` is unsafe for input; use `:encoding(UTF-8)`.
- Detect: `use utf8` as the Unicode strategy, "Wide character" warnings, double-encoded names in reports or mail.
- Fix: Decode at every input boundary and encode at every output boundary with explicit layers (and the DBD's UTF-8 option).
- Source: utf8 - https://perldoc.perl.org/utf8 ; perluniintro, Unicode I/O - https://perldoc.perl.org/perluniintro ; perldiag - https://perldoc.perl.org/perldiag

## Processes and files

### PL-05 One-string `system`, backticks and 2-arg `open` go through the shell
- Trap: `system("rsync -a $src $dest")`, `` `grep $pattern $file` `` or `open(my $fh, $ARGV[0])` are safe with filenames from users, config or feeds.
- Reality: A single string containing shell metacharacters is run with `/bin/sh -c`. Backticks have no list form. The 1- and 2-argument `open` strips whitespace and honors mode characters, so an argument like `"rsh cat file |"` runs a command. `system` returns the wait status: the exit code is `$? >> 8`, and -1 means the program did not start.
- Detect: interpolated variables in `system`/`exec`/backticks/`qx`, 2-arg `open` with non-literal names, `if (system(...))` treated as a boolean success check.
- Fix: Use list-form `system`/`exec` (or IPC::Run3 / IPC::Open3 for output), 3-arg `open`, and check `$? >> 8`.
- Source: perlfunc system - https://perldoc.perl.org/functions/system ; perlfunc open - https://perldoc.perl.org/functions/open

### PL-06 Taint mode is opt-in, early, and can be compiled out
- Trap: "The CGI/agent endpoint runs under taint mode" by adding `-T` somewhere, and taint checking replaces input validation.
- Reality: `-T` must be seen early, usually on the command line or `#!` line; a script with `-T` on its `#!` line fails if run as `perl script.pl` without `-T`. Tainted data cannot reach `system`, `exec`, file writes and similar, and `$ENV{PATH}` must be set to trusted absolute directories. Untainting is done with regex captures, which approve whatever the pattern matches. Since 5.18, perl can be built without taint support, and with `SILENT_NO_TAINT_SUPPORT` the `-T` flag is silently ignored.
- Detect: taint mode cited as the security control; untainting with `/(.*)/`; `-T` in the shebang but a cron or systemd line running `perl script.pl`.
- Fix: Validate with tight patterns, set `$ENV{PATH}` explicitly, pass `-T` on the actual command line, and confirm with `perl -V:taint_support` on the target perl.
- Source: perlsec - https://perldoc.perl.org/perlsec ; perlrun - https://perldoc.perl.org/perlrun

## CLI and deployment

### PL-07 `GetOptions` failure must be checked
- Trap: Unknown or mistyped options stop the CLI, and `-vx` means `-v -x`.
- Reality: `GetOptions` warns and returns false on errors; the script continues unless it checks. Options are case-insensitive, may be abbreviated (unless `POSIXLY_CORRECT` is set), and bundling is off by default.
- Detect: `GetOptions(...);` without `or die`/`or pod2usage`, single-letter bundles in the usage text.
- Fix: `GetOptions(...) or pod2usage(2);` and configure `bundling` or `no_ignore_case` explicitly if the CLI needs them.
- Source: Getopt::Long - https://metacpan.org/pod/Getopt::Long

### PL-08 System perl is the OS's, and `cpanm` without a snapshot is not reproducible
- Trap: Install CPAN modules into the distro perl with `sudo cpan`, and deploy with `cpanm --installdeps .` on each host.
- Reality: Vendor perl serves the OS's own purposes; perlbrew's authors call upgrading its CPAN modules "a bad idea". Carton records exact versions in `cpanfile.snapshot`, which must be committed. `carton install --deployment` installs only snapshot versions, and `carton exec` (or `-Ilocal/lib/perl5`) runs against `local/`.
- Detect: `sudo cpan`/`cpanm` into `/usr`, a cpanfile with no snapshot, "latest from CPAN" at deploy time.
- Fix: Use perlbrew/plenv or a dedicated perl build for the app, commit `cpanfile.snapshot`, and deploy with `carton install --deployment`.
- Source: perlbrew - https://perlbrew.pl/ ; Carton - https://metacpan.org/pod/Carton
