# Theme Mockup Pages

The page set, the parts every page shares, and what each page must show. The mockup is a static preview of a classic WordPress theme, so every page mirrors what the matching WordPress template would render.

## Shared Parts (every page)

Every page has the same header, footer, and (unless the user said no sidebar) sidebar. The markup is identical on every page, except for the `current-menu-item` class moving to the active menu link.

**Header**
- Skip link (`.skip-link.screen-reader-text`) to `#main` as the first focusable element
- Site title (links to `index.html`) and tagline
- Primary menu as `<nav>` > `<ul class="menu">` with `li.menu-item`. Include one item with a dropdown (`li.menu-item-has-children` > `ul.sub-menu`) and mark the current page with `current-menu-item`
- Mobile menu toggle button with `aria-expanded` and `aria-controls`, working through a few lines of plain JS
- A search form (`role="search"`, labelled input, submit button) that submits to `search.html`

**Sidebar** (`<aside>` with widget blocks, each a heading plus content)
- Search form
- Recent Posts (5 links to `single.html`)
- Categories (links to `category.html`, with post counts)
- Tag cloud (links to `tag.html`, 3 visibly different sizes)
- Archives (month links to `archive.html`)

**Footer**
- 3 widget columns (for example, about text, a link list, and social links)
- Footer menu
- Copyright line with the site name and the current year

## Post Card (used on every listing page)

Featured image, category badge, title linking to `single.html`, date (`<time datetime>`), author, comment count, excerpt, and a "Read more" link. Include one card with no featured image, and one marked `.sticky` with a visible "Featured" label.

**Pagination:** `nav.navigation.pagination` > `.nav-links` with `.page-numbers` links, `span.page-numbers.current`, `.dots`, and prev/next links.

## Pages

| File | WordPress template | Must show |
|------|--------------------|-----------|
| `index.html` | Blog posts index | 6-9 post cards (including the no-image and sticky variants), pagination |
| `single.html` | Single post | See **Single Post** below |
| `page.html` | Static page | Page title, full-width content with the same content styles as a post, no meta, no comments. Treat it as an "About" page. |
| `archive.html` | Date archive | Archive header ("Month: March 2026"), post cards, pagination |
| `category.html` | Category archive | Header with the category name and a one-paragraph description, post cards, pagination |
| `tag.html` | Tag archive | Header with the tag name, post cards, pagination |
| `author.html` | Author archive | Author header (avatar, name, bio, post count), post cards, pagination |
| `search.html` | Search results | Header ("Search results for: …") with the query, a search form repeated in the content, result cards (title, excerpt, no image), then an empty-state block showing what "no results" looks like, clearly labelled as the alternate state |
| `404.html` | Not found | Friendly message, search form, links to Home and the 5 recent posts |

Add `front-page.html` (a static home page) only if the user asks for one.

## Single Post

In order:
1. Category badge, title, and meta: author (linking to `author.html`), date, reading time, comment count
2. Featured image with a caption
3. The content showcase below
4. Tag list (links to `tag.html`)
5. Author box: avatar, name, bio, link to `author.html`
6. Previous/next post navigation (`nav.navigation.post-navigation`)
7. Comments (see below)

**Content showcase.** The body must exercise every element a writer can produce, so the style covers all of them:
- Paragraphs with bold, italic, a link, and inline `code`
- H2 to H5 headings
- Ordered, unordered, and nested lists
- A blockquote with a citation, and a pull quote (`.wp-block-pullquote`)
- An image with a caption (`figure.wp-caption` / `figcaption.wp-caption-text`)
- Floated images using `.alignleft` and `.alignright` with text wrapping around them, and a `.aligncenter` image
- A 3-image gallery (`.gallery` or `.wp-block-gallery`)
- A table with a header row
- A preformatted code block (`<pre><code>`)
- A horizontal rule
- A button (`.wp-block-button__link`)

**Comments** (`#comments`)
- Heading with the comment count
- `ol.comment-list` with at least 4 comments. One reply is nested in `ol.children`, and one comment is by the post author, marked `.bypostauthor` with a visible "Author" label. Each comment shows an avatar, name, date, text, and a Reply link.
- Comment form: labelled Name, Email, Website, and Comment fields, a cookie consent checkbox, and a submit button

## Content Rules

- The site is one fictional blog, used consistently on every page. Use the name and niche the user gives. Otherwise pick a neutral, clearly fictional name and a topic that suits the style.
- Reuse the same post titles, authors, categories, and tags across pages, so the links between pages make sense.
- Use placeholder photos from `https://picsum.photos/seed/<word>/<w>/<h>`, with one fixed seed per image so they stay the same between loads. Every image has a descriptive `alt`, or `alt=""` if it is decorative.
- Placeholder copy must read as plausible blog writing. Never state real-world facts, statistics, or testimonials as true.
