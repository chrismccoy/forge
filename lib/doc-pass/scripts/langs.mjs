/**
 * Per-language settings for the tree-sitter checker.
 *
 * Every language other than JS / TS (which lib.mjs parses with Babel) is
 * described here: the file names it covers, the grammar to load, its line
 * comment marker, the comments that are code (frozen) or must survive
 * (kept), the directives that bind to the next line, and the declarations
 * the coverage scan requires a doc comment on.
 */

/**
 * Grammar sources. `vscode` is @vscode/tree-sitter-wasm (maintained, newer
 * grammars); `wasms` is tree-sitter-wasms (older, but has Kotlin, Swift, Dart, Elixir and C).
 *
 * @type {Object<string, string>}
 */
export const GRAMMAR_DIRS = {
	vscode: '@vscode/tree-sitter-wasm/wasm',
	wasms: 'tree-sitter-wasms/out',
};

// Comments that are code in every language: license text, generated-file
// markers, spell-checker and IDE directives.
const SHARED_WHOLE = [
	/^(cspell|spell-checker):/i,
	/^(noinspection|NOSONAR|language=)/,
];
const SHARED_WHOLE_LINE = /^(@generated\b|@license\b|Copyright\b|\(c\)\s*\d|©|SPDX-License-Identifier|.*\bGNU (Lesser |Affero )?General Public License|Permission is hereby granted|Licensed under the|For the full copyright and license information)/;

/**
 * Language table. Fields:
 * - `exts` / `names`: file extensions and bare file names covered.
 * - `exclude`: paths that look like the language but are templates.
 * - `grammar`: [source, name] of the wasm grammar.
 * - `line`: the line comment marker, used by the self-test.
 * - `whole`: patterns, tested against the comment body (markers stripped),
 *   that freeze a whole comment.
 * - `frozenLine` / `keptWhole` / `keptTyped`: tag-line patterns, as in lib.mjs.
 * - `wholeRaw`: a pattern tested against the raw comment text (markers kept).
 * - `keptRaw`: the same, for one-line comments kept whole (type annotations).
 * - `nextLine`: directives that must stay the last comment before their code.
 * - `doc`: tells whether a comment's raw text is a doc comment.
 *
 * @type {Object<string, Object>}
 */
export const LANGS = {
	php: {
		exts: [ '.php', '.phtml', '.inc' ],
		exclude: /\.blade\.php$/,
		grammar: [ 'vscode', 'php' ],
		line: '//',
		whole: [ /^phpcs:(ignore|disable|enable)/i, /^@codingStandardsIgnore/, /^@phpstan-ignore/, /^@psalm-suppress/, /^php-cs-fixer:/, /^translators:/i ],
		frozenLine: /^@(test|dataProvider|depends|group|ticket|covers\w*|uses|requires|runInSeparateProcess|runTestsInSeparateProcesses|preserveGlobalState|backupGlobals|backupStaticAttributes|doesNotPerformAssertions|expectedException\w*|before\w*|after\w*|testWith|testdox|small|medium|large|noinspection|codeCoverageIgnore\w*|deprecated|internal|phpstan-ignore\S*|psalm-suppress|required|final|readonly|pure|immutable|infection-ignore-all|response|status|unauthenticated|operationId|requestMediaType)\b|^@([A-Z]\w*|\w+\\)/,
		keptWhole: /^@(since|see|link|author|api)\b/,
		// `@property` / `@method` blocks feed Larastan and IDE helpers even without --checked-types.
		keptTyped: /^@(phpstan-\S+|psalm-\S+|template\S*|mixin|extends|implements|property(-read|-write)?|method)\b/,
		checkedTyped: /^@(param|return|var|throws)\b/,
		nextLine: /phpcs:ignore|@phpstan-ignore\b|@phpstan-ignore-next-line|@psalm-suppress|translators:/,
		doc: ( t ) => t.startsWith( '/**' ),
	},
	python: {
		exts: [ '.py', '.pyi' ],
		grammar: [ 'vscode', 'python' ],
		line: '#',
		whole: [ /^!/, /^-\*-.*coding/, /^(vim?:.*)?coding[:=]/, /^type:/, /^noqa\b/i, /^(pylint|flake8|mypy|pyright|pyre-\w+|ruff|isort|pragma|fmt|yapf|ty|pyrefly|autopep8|pycodestyle|pytype):/, /^(nosec|nosemgrep|skipcq|lgtm)\b/, /^codespell:ignore\b/ ],
		frozenLine: /^\.\. deprecated::/,
		keptWhole: /^\.\. (versionadded|versionchanged)::/,
		keptTyped: null,
		nextLine: /^#\s*(type:\s*ignore|noqa|pragma|fmt:\s*skip)/,
		docstrings: true,
		doc: ( t ) => t.startsWith( '#' ),
	},
	go: {
		exts: [ '.go' ],
		grammar: [ 'vscode', 'go' ],
		line: '//',
		// swaggo / swag annotations (`// @Summary`, `// @Param`, `// @Router` …)
		// generate the OpenAPI spec, one line per comment.
		whole: [ /^@[A-Za-z][\w.-]*(\s|$)/, /^go:\w+/, /^\+build\b/, /^nolint\b/, /^#?nosec\b/, /^revive:(disable|enable)/, /^exhaustive:ignore/, /^lint:(ignore|file-ignore)/, /^export\s+\w+$/, /^line\s+\S+:\d+/, /^extern\b/, /^#cgo\b/, /^(Unordered )?[Oo]utput:/ ],
		frozenLine: /^Deprecated:/,
		keptWhole: null,
		keptTyped: null,
		nextLine: /^\/\/(go:(?!build\b)|nolint|lint:ignore)/,
		doc: ( t ) => t.startsWith( '//' ) || t.startsWith( '/*' ),
	},
	rust: {
		exts: [ '.rs' ],
		grammar: [ 'vscode', 'rust' ],
		line: '//',
		whole: [ /^~/, /^rustfmt-/, /^cbindgen:/ ],
		frozenLine: null,
		keptWhole: /^SAFETY:/,
		keptTyped: null,
		nextLine: null,
		doctests: true,
		doc: ( t ) => /^\/\/\/[^/]|^\/\/\/$|^\/\*\*[^*]|^\/\/!|^\/\*!/.test( t ),
	},
	ruby: {
		exts: [ '.rb', '.rake', '.gemspec', '.ru', '.thor' ],
		names: [ 'Rakefile', 'Gemfile', 'Guardfile', 'Capfile', 'Brewfile', 'Vagrantfile' ],
		grammar: [ 'vscode', 'ruby' ],
		line: '#',
		whole: [ /^!/, /^(frozen_string_literal|encoding|coding|warn_indent|warn_past_scope|shareable_constant_value|typed|rbs_inline):/, /^-\*-.*(coding|frozen_string_literal)/, /^@(type\s+(var|self|ivar|instance|module|const|block|break)|implements)\b/, /^rubocop:(disable|enable|todo)/, /^:(nodoc|stopdoc|startdoc|enddoc|doc):/, /^steep:ignore/, /^:/, /^@rbs\b/, /^standard:(disable|enable)/ ],
		frozenLine: /^@(!\w+|deprecated|api\s+private)\b/,
		keptWhole: /^@(see|since|author)\b/,
		keptTyped: null,
		nextLine: /rubocop:(disable|todo)|standard:disable|steep:ignore|^#:/,
		doc: ( t ) => t.startsWith( '#' ),
	},
	java: {
		exts: [ '.java' ],
		grammar: [ 'vscode', 'java' ],
		line: '//',
		whole: [ /^CHECKSTYLE:(OFF|ON)/, /^@formatter:(off|on)/, /^NOPMD/, /^\$NON-NLS/, /^spotless:(off|on)/, /^SUPPRESS CHECKSTYLE/, /^(fall ?through|falls through)\.?$/i ],
		frozenLine: /^@(deprecated|hide)\b/,
		keptWhole: /^@(since|see|author|serial\w*)\b/,
		keptTyped: null,
		nextLine: /noinspection|CHECKSTYLE|NOPMD/,
		doc: ( t ) => t.startsWith( '/**' ),
	},
	kotlin: {
		exts: [ '.kt', '.kts' ],
		grammar: [ 'wasms', 'kotlin' ],
		line: '//',
		whole: [ /^ktlint-(disable|enable)/, /^@formatter:(off|on)/, /^detekt:/, /^spotless:(off|on)/ ],
		frozenLine: /^@(deprecated|suppress)\b/,
		keptWhole: /^@(since|see|author|sample)\b/,
		keptTyped: null,
		nextLine: /noinspection|ktlint-disable/,
		doc: ( t ) => t.startsWith( '/**' ),
	},
	csharp: {
		exts: [ '.cs' ],
		grammar: [ 'vscode', 'c-sharp' ],
		line: '//',
		whole: [ /^ReSharper (disable|restore)/, /^<auto-?generated/, /^dotcover (disable|enable)/i, /^<copyright\b/i ],
		frozenLine: /^<include\b/,
		keptWhole: /^<inheritdoc\b/,
		keptTyped: null,
		nextLine: /ReSharper disable once/,
		doc: ( t ) => /^\/\/\/[^/]|^\/\/\/$|^\/\*\*/.test( t ),
	},
	swift: {
		exts: [ '.swift' ],
		grammar: [ 'wasms', 'swift' ],
		line: '//',
		whole: [ /^swiftlint:(disable|enable)/, /^swift-format-ignore/, /^swift-tools-version/, /^sourcery:/, /^periphery:ignore/, /^swiftformat:(disable|enable|options|sort)/ ],
		frozenLine: null,
		keptWhole: null,
		keptTyped: null,
		nextLine: /swiftlint:disable:next|swift-format-ignore|periphery:ignore|swiftformat:disable:next/,
		doc: ( t ) => /^\/\/\/[^/]|^\/\/\/$|^\/\*\*/.test( t ),
	},
	dart: {
		exts: [ '.dart' ],
		grammar: [ 'wasms', 'dart' ],
		line: '//',
		// Analyzer suppressions, coverage markers, the language-version
		// override and formatter switches.
		whole: [ /^ignore(_for_file)?:/, /^coverage:ignore-(line|start|end|file)\b/, /^@dart\s*=/, /^dart format (off|on)\b/ ],
		frozenLine: null,
		// dartdoc templates and macros: other doc comments include them by name.
		keptWhole: /^\{@(template|endtemplate|macro|tool|end-tool|inject-html|youtube|animation|example|nodoc)\b|^@nodoc\b/,
		keptTyped: null,
		nextLine: /^\/\/\s*ignore:/,
		doc: ( t ) => /^\/\/\/[^/]|^\/\/\/$|^\/\*\*[^*]/.test( t ),
	},
	elixir: {
		exts: [ '.ex', '.exs' ],
		grammar: [ 'wasms', 'elixir' ],
		line: '#',
		// Credo, coveralls and Sobelow directives.
		whole: [ /^credo:disable-for-(this-file|next-line|lines:)/, /^coveralls-ignore-(start|stop|next-line)/, /^sobelow_skip\b/ ],
		frozenLine: null,
		keptWhole: null,
		keptTyped: null,
		nextLine: /credo:disable-for-next-line|coveralls-ignore-next-line|sobelow_skip/,
		docstrings: true,
		// ExUnit doctests: `iex>` prompts and their `...>` continuations.
		doctest: /^(iex|\.\.\.)(\(\d+\))?>/,
		doc: ( t ) => t.startsWith( '#' ),
	},
	erlang: {
		exts: [ '.erl', '.hrl', '.escript' ],
		// Read by lexers.mjs: no tree-sitter grammar.
		reader: 'erlang',
		line: '%%',
		// Emacs mode lines and erlfmt pragmas; escript `%%!` emulator flags by their raw text.
		whole: [ /^-\*-/, /^erlfmt-ignore/, /^@(format|noformat)\s*$/ ],
		wholeRaw: /^%%!/,
		// EDoc tags that hide or deprecate a function in the generated docs.
		frozenLine: /^@(private|hidden|deprecated|equiv)\b/,
		keptWhole: /^@(see|since|author|copyright|version|reference)\b/,
		keptTyped: null,
		nextLine: /erlfmt-ignore/,
		doc: ( t ) => t.startsWith( '%' ),
	},
	haskell: {
		exts: [ '.hs', '.hsc' ],
		// Read by lexers.mjs: no tree-sitter grammar.
		reader: 'haskell',
		line: '--',
		// HLint and formatter switches; `{-# … #-}` pragmas, LiquidHaskell
		// `{-@ … @-}` annotations and Stack script `{- stack … -}` headers by their raw text.
		whole: [ /^HLINT\b/i, /^(ORMOLU|FOURMOLU)_(DISABLE|ENABLE)/ ],
		wholeRaw: /^\{-[#@]|^\{-\s*stack\b/,
		frozenLine: null,
		keptWhole: /^@since\b/,
		keptTyped: null,
		nextLine: null,
		// doctest / cabal-docspec examples in Haddock comments.
		doctestComments: true,
		doctest: /^(>>>|prop>)/,
		// Haddock: `-- |`, `-- ^`, `-- $name`, `-- *` and `{- | … -}`.
		doc: ( t ) => /^(--\s*[|^$*]|\{-\s*[|^$])/.test( t ),
	},
	powershell: {
		exts: [ '.ps1', '.psm1', '.psd1' ],
		grammar: [ 'vscode', 'powershell' ],
		line: '#',
		// `#Requires`, regions, Authenticode signature blocks, PowerShellGet
		// script metadata and external help pointers.
		whole: [ /^Requires\s+-/i, /^(end)?region\b/i, /^SIG # (Begin|End) signature block/, /^PSScriptInfo\b/, /^\.(EXTERNALHELP|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE)\b/i ],
		wholeRaw: /^# SIG # /,
		// External help pointers count on any line of a help block.
		frozenLine: /^\.(EXTERNALHELP|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE)\b/i,
		// Comment-based help: Get-Help reads each keyword, and `.PARAMETER`
		// names a real parameter.
		keptWhole: /^\.(SYNOPSIS|DESCRIPTION|PARAMETER\s+\S+|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY)\s*$/i,
		keptTyped: null,
		nextLine: null,
		doc: ( t ) => t.startsWith( '<#' ) || t.startsWith( '#' ),
	},
	lua: {
		exts: [ '.lua', '.rockspec' ],
		// Read by lexers.mjs: the bundled Lua grammar gives different trees for
		// the same text from one parse to the next.
		reader: 'lua',
		line: '--',
		// luacheck, StyLua, selene and LuaLS diagnostics directives.
		whole: [ /^-?\s*luacheck:/, /^-?\s*stylua:\s*ignore/, /^-?\s*selene:\s*allow/, /^-?\s*@diagnostic\s+(disable|enable)/ ],
		frozenLine: /^@(deprecated|private|local)\b/,
		// LDoc structure tags, and LuaLS / EmmyLua definitions, which feed the
		// language server's type checks, survive whole.
		keptWhole: /^@(see|since|author|module|classmod|submodule|script|usage|phases|class|field|type|alias|generic|overload|cast|enum|meta|operator|nodiscard|async|vararg)\b/,
		// LDoc `@param name …` / `@tparam type name …`: the first word survives.
		keptTyped: /^@(param|return|tparam|treturn)\b/,
		// LuaLS `---@param name type` / `---@return type`: the whole line.
		keptRaw: /^---@(param|return)\b/,
		nextLine: /luacheck:\s*ignore|stylua:\s*ignore\b(?!\s*(start|end))|@diagnostic\s+disable-next-line/,
		doc: ( t ) => /^---(?!-)|^--\[=*\[/.test( t ),
	},
	perl: {
		exts: [ '.pl', '.pm', '.t', '.psgi', '.cgi' ],
		// Read by lexers.mjs: no tree-sitter grammar.
		reader: 'perl',
		line: '#',
		// Editor mode lines, Dist::Zilla / Pod::Weaver markers that generate
		// POD or code, and (by raw text) shebangs, Perl::Critic `## no critic`
		// and perltidy `#<<<` / `#>>>` skip markers.
		whole: [ /^-\*-/, /^vim?:/, /^(PODNAME|ABSTRACT|VERSION|AUTHORITY)\b:?/ ],
		wholeRaw: /^(#!|##\s*(no|use)\s+critic\b|#(<<<|>>>))/,
		frozenLine: null,
		// POD blocks aimed at one formatter or tool.
		keptWhole: /^=(begin|end|for|encoding)\b/,
		keptTyped: null,
		nextLine: null,
		// POD blocks and `#` comments.
		doc: ( t ) => t.startsWith( '=' ) || t.startsWith( '#' ),
	},
	clojure: {
		exts: [ '.clj', '.cljs', '.cljc', '.cljd', '.bb' ],
		// Read by clojure.mjs: no tree-sitter grammar.
		reader: 'clojure',
		line: ';;',
		// Emacs mode lines; shebangs and `;!zprint` directives by their raw text.
		whole: [ /^-\*-/ ],
		wholeRaw: /^(#!|;+!zprint\b)/,
		frozenLine: null,
		keptWhole: null,
		keptTyped: null,
		nextLine: /^;+!zprint/,
		docstrings: true,
		doc: ( t ) => t.startsWith( ';' ) || t.startsWith( '"' ),
	},
	c: {
		exts: [ '.c' ],
		grammar: [ 'wasms', 'c' ],
		line: '//',
		// The fall-through form follows GCC's -Wimplicit-fallthrough: the whole comment must match.
		whole: [ /^NOLINT/, /^clang-format (off|on)/, /^((else,? |intentional(ly)? )?fall(s | |-)?thr(ough|u))[ \t.!]*(-.*)?(\*\/)?$/i, /^IWYU pragma:/, /^cppcheck-suppress/, /^NOTREACHED/, /^LINTED/, /^coverity\[/, /^lint\b/, /^(ARGSUSED|VARARGS)\d*/ ],
		frozenLine: /^[@\\](deprecated|internal|cond|endcond)\b/,
		keptWhole: /^[@\\](see|since|author)\b/,
		keptTyped: null,
		nextLine: /NOLINTNEXTLINE|cppcheck-suppress|fall(s | |-)?thr(ough|u)/i,
		doc: ( t ) => /^\/\*\*[^*]|^\/\*!|^\/\/\/[^/]|^\/\/\/$|^\/\/!/.test( t ),
	},
};

// C++ shares C's comment rules; headers use the C++ grammar, which parses
// nearly all C headers as well.
LANGS.cpp = { ...LANGS.c, exts: [ '.cc', '.cpp', '.cxx', '.c++', '.hpp', '.hh', '.hxx', '.h', '.ipp', '.inl' ], grammar: [ 'vscode', 'cpp' ] };

// Fallback grammars for JS / TS files that Babel cannot parse (see model() in
// lib.mjs): the broken regions are locked as in other languages. No extensions,
// so langFor() never picks them; lib.mjs classifies their comments.
LANGS.javascript = { exts: [], grammar: [ 'vscode', 'javascript' ], line: '//', whole: [], doc: ( t ) => t.startsWith( '/**' ) };
LANGS.typescript = { ...LANGS.javascript, grammar: [ 'vscode', 'typescript' ] };
LANGS.tsx = { ...LANGS.javascript, grammar: [ 'vscode', 'tsx' ] };

for ( const l of Object.values( LANGS ) ) {
	l.whole = [ ...l.whole, ...SHARED_WHOLE ];
	l.wholeLine = SHARED_WHOLE_LINE;
}

/**
 * Finds the language for a path.
 *
 * @param {string} file Path or file name.
 * @return {string|null} Language key, or null when no tree-sitter language covers it.
 */
export function langFor( file ) {
	const base = file.split( '/' ).pop();
	for ( const [ key, l ] of Object.entries( LANGS ) ) {
		if ( l.exclude?.test( file ) ) {
			return null;
		}
		if ( l.names?.includes( base ) || l.exts.some( ( e ) => base.endsWith( e ) ) ) {
			return key;
		}
	}
	return null;
}
