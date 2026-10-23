## Ruby rules

### Files and tools

- **In scope:** `.rb`, `.rake`, `.gemspec`, `.ru`, `.thor`, and `Rakefile`, `Gemfile`, `Guardfile`, `Capfile`, `Brewfile`, `Vagrantfile`.
- **Out of scope:** ERB, HAML and Slim views (read for facts only), `db/schema.rb` and `db/structure.sql` (generated), `vendor/`, `bin/` binstubs, `config/credentials*` (never open them, `.env` or `*.key`).
- **Locked regions.** The checker's grammar cannot parse anonymous block forwarding (`def m(&) = foo(&)`, `form_with **attrs, &`). The region around it is compared byte for byte, comments included, as **Locked regions** in the universal rules describes. Document the method above its `def`; add nothing inside the region.
- **Checks:**
  - `ruby -c file.rb` only when `ruby -v` matches `.ruby-version`; otherwise the checker parse is the syntax check.
  - `bundle exec rubocop --format json <files>`, compared per cop before and after. Comments can trip `Layout/LeadingCommentSpace`, `Layout/CommentIndentation`, `Layout/EmptyLineAfterMagicComment`, `Layout/TrailingWhitespace`, `Layout/EmptyLinesAroundClassBody` and `Style/Documentation`.
  - Tests: `bin/rails test` (minitest) or `bundle exec rspec`; the count must not move.
  - Types: `srb tc` when `sorbet/` exists; `steep check` with a `Steepfile`.

### Doc comment style

- **Detect the dialect** from existing comments and config, then follow it everywhere:
  - **YARD:** a `.yardopts`, `yard` in the `Gemfile`, or existing `@param` / `@return` tags.
  - **RDoc:** `:call-seq:` blocks, `+code+` markup, labeled lists (`[name] text`).
  - **Plain prose:** no tags. Rails omakase apps (`rubocop-rails-omakase`) use short `#` sentences that say why. Follow that: no `@param` / `@return`.
- **Form:** `#` lines directly above the `class`, `module` or `def`, no blank line between. Never `=begin` / `=end`.
- **Voice:** a third-person summary ending in a period (`# Returns the cards the user can see.`), then detail as a second paragraph after a bare `#` line.
- **YARD tags**, in the project's existing order (`@param [Type] name` or `@param name [Type]`):
  - `@param [String] email Address to invite.` for every parameter, keywords included; `@option opts [Integer] :limit` for options hashes.
  - `@yield` / `@yieldparam` / `@yieldreturn` for methods that take a block.
  - `@return [Array<Card>]` unless the method's value is unused (`@return [void]`).
  - `@raise [ActiveRecord::RecordNotFound] when …` for each error raised on purpose.
  - `@example` only when the project already uses them.
  - Keep existing types; report a wrong one as a bug.
- **`# :nodoc:`** after a `class`, `module` or `def` line hides it from RDoc and YARD. It is frozen; on the same line it does not count as the doc comment.
- **Inline comments:** `#` full sentences ending in a period, one space after `#`.

### Coverage

- A doc comment on every `class`, `module`, `def` and `def self.x` (methods inside `class << self` and concern blocks included).
- Exempt: minitest `test_*` methods under `test/`. `test "…" do`, `describe` and `it` blocks need none; test classes and helpers do.
- **File header:** a file whose only top-level statement is one `class` or `module` (nesting included) is covered by that declaration's doc. Any other file (`require` before the class, `routes.draw`, rake tasks, `config.ru`, initializers) needs a comment before its first statement, after the magic comments, then one blank line.
- By reading (the scan cannot see them): `attr_*`, constants, `scope`, `has_many` and other macros, `define_method`, `Struct.new` / `Data.define`, rake `task` / `namespace` blocks.

### Comments that are code

Frozen, byte for byte, in place:

- Shebang (`#!`) and magic comments: `frozen_string_literal:`, `encoding:` / `coding:` / `-*- coding … -*-`, `warn_indent:`, `warn_past_scope:`, `shareable_constant_value:`, and Sorbet's `# typed:` sigil. They work only in the first comment lines: never put a comment above them.
- RuboCop and Standard directives: `rubocop:disable`, `rubocop:enable`, `rubocop:todo`, `standard:disable`, `standard:enable`.
- Any comment starting with `:`: RDoc directives (`:nodoc:`, `:stopdoc:`, `:startdoc:`, `:enddoc:`, `:doc:`, `:call-seq:`, `:yields:`), SimpleCov `:nocov:`, Reek `:reek:` and rbs-inline signatures (`#: (String) -> User`).
- rbs-inline `# @rbs` lines and Steep `steep:ignore`.
- Tag lines: YARD directives (`@!attribute`, `@!method`, `@!macro`, `@!visibility`, `@!scope`, `@!group`, `@!parse`), `@deprecated`, `@api private`.
- Kept (may be added): `@see`, `@since`, `@author`.
- `rubocop:disable …`, `steep:ignore` and `#:` signatures must stay the last comment before their code: put a new comment above them.
- Never start a new comment with `:`, `!`, `@!`, `@rbs`, `@deprecated`, `@api private`, a directive word (`rubocop:`, `standard:`, `steep:`), or a magic comment name followed by `:` (`typed:`, `coding:`). Reword.

### Rails

- **`config/routes.rb` is the route map.** Its header lists resources, namespaces, `scope` / `constraints` blocks, `concern`s, mounted engines and path-rewriting middleware. Each controller action names its verb and full path (`PATCH /boards/:board_id/cards/:id`) from it.
- **Controllers:** the class comment lists its `before_action` / `skip_before_action` / `around_action` filters, with `only:` / `except:`, and what each loads or enforces. Each action: path, authorization, the params it permits (the strong-params method's keys), the response per format (`respond_to`, Turbo Stream, redirect target, status), and records written.
- **Models:** the table, then associations (`dependent:` behavior), validations, callbacks (when each runs and what it changes or enqueues), scopes, `enum` values and their meaning, `has_secure_password` / `encrypts` / `normalizes`, and included concerns. Concerns say what `included do` adds and what the host class must provide.
- **Jobs (Active Job / Solid Queue):** queue, arguments, `retry_on` / `discard_on`, concurrency limits, schedule (`config/recurring.yml`), idempotency.
- **Mailers:** each action's recipients, subject and view.
- **Action Cable channels are the event map:** `stream_from` / `stream_for` names and the payload broadcast. `broadcasts_refreshes`, `broadcast_*_to` and `turbo_stream_from` say which stream, when they fire, and which partial they render.
- **Credentials and ENV:** follow the env map. Name the key (`Rails.application.credentials.dig(:aws, :bucket)`, `ENV.fetch("PORT")`); never a value.
- **Migrations:** the header states the intent and whether `down` / `change` reverses it. Never edit migration code, names or timestamps.
- **Initializers:** what each configures or patches, and why.

### Sinatra, Rack and gems

- **Sinatra / Roda / Hanami:** each route block (`get "/notes/:id" do`) gets a comment with method, path, auth, params and statuses; `before` / `after` filters say which paths they match.
- **Rack middleware:** what `call(env)` reads from and adds to `env`, when it short-circuits (status, headers, body), and its position in `config.ru` or `config.middleware`.
- **Gems:** the top-level module documents the public API and the `configure` block. Never edit `.gemspec` fields.

### Bug report additions

- Mass assignment: `params.permit!`, `update(params[:x])` without strong params.
- SQL injection: `where("name = '#{…}'")`, `order(params[:sort])`, `find_by_sql` with interpolation.
- XSS: `html_safe`, `raw`, `<%==` on user input.
- Open redirects: `redirect_to params[:return_to]` without `allow_other_host: false` or a host check.
- N+1 queries: associations read in loops without `includes` / `preload`.
- Callbacks with side effects: emails, HTTP calls or jobs in `after_save` instead of `after_commit`.
- Missing authorization: actions that load records by ID without scoping to `Current.user` / the account.
- `send` / `constantize` / `public_send` on user input; `YAML.load` / `Marshal.load` on untrusted data.
