## PowerShell rules

### Files and tools

- In scope: `.ps1`, `.psm1`, `.psd1` (module manifests: their keys get `#` comments, no help blocks).
- Out of scope: `.ps1xml` format and type files, compiled binary modules, files that end in an Authenticode signature block (`# SIG # Begin signature block`): any edit invalidates the signature, so leave the whole file alone and list it in the report.
- Syntax check: parse each file with `[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)` when `pwsh` is available; no new errors. Baseline: `Invoke-ScriptAnalyzer -Path <files>` (PSScriptAnalyzer) before and after: no new findings; `PSProvideCommentHelp` should go down. Tests: `Invoke-Pester`.
- Pester tests often read the source as text: a regex over each line (`'^\s*Invoke-Foo\b'`) or `IndexOf('Split-WindowsImage')` inside a function's text also matches help lines. Before writing help, read the Pester tests that scan source text (`Get-Content`, `.IndexOf(`, `-match` over a script). Never start a help line, `.EXAMPLE` lines included, with a command or fragment those tests search for, and never put that fragment in help above the code the test locates. The main session's per-test comparison catches what reading misses.
- The bundled grammar mis-parses a few one-line forms (`function F { param($v) $v }`): the checker locks the enclosing statement byte for byte.

### Doc comment style

- Comment-based help, which `Get-Help` reads: a `<# … #>` block with keywords, either as the first thing inside the function body (the form winutil uses) or directly above `function` with no blank line between. Pick the project's existing placement.
- Keywords: `.SYNOPSIS` (one sentence), `.DESCRIPTION`, one `.PARAMETER <Name>` per parameter (the name must match the `param()` block), `.EXAMPLE` (a command line, then what it does), `.INPUTS`, `.OUTPUTS`, `.NOTES`, `.LINK`. Write each keyword on its own line with the text indented below it.
- `.PARAMETER` lines and the other keyword lines are kept: never rename or remove one. Add missing `.PARAMETER` entries for parameters that lack them.
- Content: what the function changes on the machine (registry keys, services, scheduled tasks, files, `winget` / `choco` installs), whether it needs elevation (`#Requires -RunAsAdministrator`), which preference variables it reads, what it writes to the pipeline versus the host, and what it throws (`throw`, `-ErrorAction Stop`).
- Classes and their members (PowerShell 5+): `#` comments above each, since comment-based help does not cover them.
- File header: a script-level `<# .SYNOPSIS … #>` block at the top of the file (after `#Requires` lines), or `#` lines.

### Coverage

- Every `function` and `filter`, every `class` and `enum`, every class method and property.
- Checked by reading: script blocks passed to `ForEach-Object`, `Register-ObjectEvent`, `Start-Job` / `Start-ThreadJob` and WPF / WinForms event handlers (`Add_Click({ … })`).

### Comments that are code

- Frozen whole comment: `#Requires …`, `#region` / `#endregion` (editors fold on them, and build scripts often split files on them), Authenticode `# SIG #` blocks, `<#PSScriptInfo … #>` metadata (PowerShellGet), `.EXTERNALHELP` / `.FORWARDHELPTARGETNAME` / `.FORWARDHELPCATEGORY` / `.REMOTEHELPRUNSPACE` pointers, plus the shared license, `@generated` and `cspell:` forms.
- `[Diagnostics.CodeAnalysis.SuppressMessageAttribute(…)]` attributes are code, not comments.
- Never put a comment inside a here-string (`@' … '@`, `@" … "@`): it is content.
- **Trigger words:** never start a new comment, or a line in one, with `region` / `endregion` (any case: `# Region settings` freezes as a `#region` marker), `Requires -`, `SIG # Begin`, `PSScriptInfo`, or an external-help keyword (`.EXTERNALHELP`, `.FORWARDHELPTARGETNAME`). Reword (`# Settings for the region list.`).

### WPF tools, modules and DSC

- **WPF / XAML apps** (winutil): handlers wired by name (`$sync.WPFButton.Add_Click`) get one line naming the control. Functions that read `$sync` (the shared synchronized hashtable) say which keys they read and write and which runspace they run in.
- **Runspaces and jobs:** say what runs on the background runspace, what it shares (`$sync`, `[hashtable]::Synchronized`), and how results reach the UI thread (`Dispatcher.Invoke`).
- **Modules:** the manifest's `FunctionsToExport` is the public API; private helpers get `#` comments.
- **Environment:** `$env:` reads form the env map; registry paths read or written are listed once per function.

### Bug report additions

- `Invoke-Expression` on downloaded or user-supplied text; `iwr | iex` without checksum verification.
- Registry or service changes without a restore path; missing `-ErrorAction Stop` before `try` / `catch`.
- `$ErrorActionPreference = 'SilentlyContinue'` hiding failures; plain-text credentials in parameters.
