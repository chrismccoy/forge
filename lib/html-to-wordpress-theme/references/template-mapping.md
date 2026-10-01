# Source HTML → WordPress Template Mapping

When asking for source HTML, present this mapping table to the user so they know which templates they can drive from their own designs (vs. letting Claude derive defaults). Match by filename:

| Source HTML file | Drives WordPress template(s) | Required? |
|-----------------|------------------------------|-----------|
| `index.html` | `index.php` (homepage / archive fallback) | **Yes** |
| `single.html` | `single.php` (single post) | Recommended - if absent, derive from `index.html` post-card structure with reasonable expansion. Flag this assumption in ⑩. |
| `page.html` | `page.php` (static pages) | Optional - if absent, derive from `single.html` design with the post-meta stripped. |
| `archive.html` | `archive.php`, `category.php`, `tag.php` (any archive view) - overridden by the more-specific files below if present | Optional |
| `category.html` | `category.php` specifically (overrides `archive.html` for the category archive) | Optional |
| `tag.html` | `tag.php` specifically (overrides `archive.html` for the tag archive) | Optional |
| `search.html` | `search.php` (search results) | Optional |
| `404.html` | `404.php` | Optional - if absent, generate a minimal styled 404 matching theme tokens. |
| `comments.html` | Markup hint for `comments.php`, layered onto WordPress's `comment_form()` + `wp_list_comments()` output | Optional |
| `landing.html`, `contact.html`, `about.html`, etc. (any name not above) | Custom page template at `template-pages/template-{name}.php`, surfaced in wp-admin under Page Attributes → Template | Optional |

Echo this table back to the user when asking for source HTML so they can answer in one shot ("I have index.html, single.html, archive.html, and a contact.html"). If the user provides a file whose name doesn't fit this convention, ask which template it should drive before guessing.
