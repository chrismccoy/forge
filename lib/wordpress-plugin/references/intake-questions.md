# Intake questions

The full text and option lists for the seven intake questions. Ask them in order (Q1 to Q7). Free-text questions are plain chat prompts; multiple-choice questions are plain-text numbered checklists, each with its `Other (specify)` escape.

## Q1 - Plugin name (free text)

```
What is the plugin called? (e.g. "Acme Bookings", "Smart Redirects Pro", "Membership Tiers")
```

Use this exact name in the plugin header, `Plugin Name:` field, and main display labels.

## Q2 - Functionality (multi-select MC)

> Which WordPress mechanisms does the plugin use? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| Custom Post Types & Taxonomies | `register_post_type()` + `register_taxonomy()` with capability mapping |
| Settings / Options Page | Full Settings API implementation with tabs and sanitization callbacks |
| Gutenberg Blocks | `block.json` + `register_block_type()` + edit.js + save.js + style.scss |
| Shortcodes | `add_shortcode()` with attribute sanitization and output escaping |
| REST API endpoints | `register_rest_route()` with `permission_callback` + schema |
| WP-CLI commands | `WP_CLI::add_command()` with subcommands and synopsis |
| Cron / Scheduled tasks | `wp_schedule_event()` + activation hook registration + cleanup on deactivate |
| Custom Database Tables | `dbDelta()` schema, charset/collation, indexes, version-bump migrations |
| User Roles / Capabilities | `add_role()` + `add_cap()` with proper cleanup on uninstall |
| Email Notifications | `wp_mail()` wrapper with templates and HTML headers |
| Frontend Forms | Nonced AJAX form with server-side validation |
| Dashboard Widget | `wp_add_dashboard_widget()` with cached data fetch |
| Import / Export | JSON/CSV export endpoint and import handler with file validation |
| Analytics / Activity Logging | Custom log table + admin viewer with filters |
| Custom User Meta | `register_meta()` + profile field rendering with sanitization |
| Other (specify) | Generate scaffolding for the mechanism the user names |

## Q3 - Specific feature detail (free text)

```
In 2-4 sentences, describe what the plugin actually DOES at the user level.
What problem does it solve? What is the happy-path user flow?
(Example: "Lets shop owners offer time-slot bookings on any WooCommerce product.
Customers pick a date and slot at checkout; staff see all bookings in a calendar
view in WP admin and receive an email when one is made.")
```

This drives the domain logic, naming of classes, and copy in the README.txt.

## Q4 - Target users (single-select MC)

> Who is the primary audience using this plugin? Pick one.

| Option | Implication |
|--------|-------------|
| Site administrators only | Generate admin-side features; minimal/no frontend output |
| Editors and authors | Generate role-aware capability checks; meta boxes on post screens |
| Frontend site visitors | Generate public-facing shortcodes/blocks; minimize admin surface |
| Developers (extending via hooks/API) | Generate documented hooks, filters, and REST endpoints; ship a `docs/` folder |
| Multisite network administrators | Generate network-activation support, `is_multisite()` branches, network settings page |
| Mixed / multiple of the above | Generate full surface (admin + frontend + extensibility) |
| Other (specify) | Adapt the surface to the audience the user names |

## Q5 - Admin interface components (multi-select MC)

> Which admin UI components does the plugin need? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| Top-level admin menu | `add_menu_page()` with custom icon (dashicons) |
| Submenu under Settings | `add_options_page()` |
| Submenu under Tools | `add_management_page()` |
| Meta boxes on post types | `add_meta_box()` with nonce + capability check on save |
| Custom post type list-table screens | `WP_List_Table` subclass with sortable columns and bulk actions |
| Dashboard widget | `wp_add_dashboard_widget()` |
| Admin notices | Dismissible notices with user-meta persistence |
| Help tabs on plugin screens | `get_current_screen()->add_help_tab()` |
| None (frontend-only plugin) | Skip all admin UI scaffolding |
| Other (specify) | Generate the admin component the user names |

## Q6 - Frontend display surfaces (multi-select MC)

> How does the plugin render on the public site? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| Shortcodes | `add_shortcode()` handlers |
| Gutenberg blocks | `block.json` + React edit component + save function + frontend `render_callback` |
| Classic widgets | `WP_Widget` subclass |
| Template tags / functions | Public `{prefix}_render_*()` functions for themes to call ({prefix} = the plugin's function prefix) |
| Auto-injected via `the_content` filter | Filter-based injection with opt-out via post meta |
| REST-driven SPA / headless | REST endpoints + minimal client-side fetch demo |
| Custom page templates | `page-*.php` templates registered via `theme_page_templates` filter |
| None (admin-only plugin) | Skip all frontend scaffolding |

If Q5 and Q6 are both `None`, the plugin would have no admin UI and no frontend output: confirm with the user that this is intended (e.g. a hooks-only or integration plugin) before generating.
| Other (specify) | Generate the frontend surface the user names |

## Q7 - Third-party integrations (multi-select MC)

> Which external services or plugins does this integrate with? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| None | Skip integration scaffolding |
| WooCommerce | Hooks into WC actions/filters; checks `class_exists( 'WooCommerce' )` before booting integration |
| BuddyPress / bbPress | Hooks into BP/bbP actions with `function_exists()` guards |
| Advanced Custom Fields (ACF) | Registers field groups via PHP; gracefully degrades if ACF inactive |
| Elementor | Custom widget class extending `Widget_Base` |
| External REST API | HTTP client wrapper using `wp_remote_get()` / `wp_remote_post()` with retries and error handling |
| Stripe or PayPal | Server-side payment intent / order creation with webhook handler |
| Mailchimp / ConvertKit / SendGrid | Newsletter signup handler; read the API key from a `wp-config.php` constant (recommended) or store it in an option, documented as plaintext - WordPress has no built-in option encryption, so never claim it is encrypted |
| Google Analytics / Tag Manager | Frontend tracking snippet enqueue with cookie-consent gate |
| OAuth providers (Google, GitHub, etc.) | OAuth callback handler + state nonce + user linking |
| Webhooks (incoming) | REST endpoint with HMAC signature verification |
| Webhooks (outgoing) | Async dispatcher using Action Scheduler if available, falls back to wp-cron |
| Other (specify) | Generate an integration scaffold for the service the user names |
