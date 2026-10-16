# Tailwind CSS Advanced Layout Techniques

**Contents:** CSS Grid Mastery · Advanced Flexbox Patterns · Container Queries · Position and Layering · Overflow and Scrolling · Aspect Ratio and Object Fit · Advanced Spacing · Multi-Column Layout · Responsive Patterns · Print Styles · Best Practices

## CSS Grid Mastery

### Complex Grid Layouts

```html
<!-- Holy grail: header, footer, main with left and right sidebars. Single column on mobile. -->
<div class="grid min-h-dvh grid-rows-[auto_1fr_auto]">
  <header class="border-b border-gray-200">Header</header>
  <div class="grid grid-cols-1 md:grid-cols-[16rem_1fr] lg:grid-cols-[16rem_1fr_18rem]">
    <!-- main first in the DOM; grid lines place the sidebars around it -->
    <main class="min-w-0 p-6 md:col-start-2 md:row-start-1">Main content</main>
    <nav aria-label="Section" class="bg-gray-50 p-4 md:col-start-1 md:row-start-1">Sidebar</nav>
    <aside class="hidden bg-gray-50 p-4 lg:col-start-3 lg:row-start-1 lg:block">Right sidebar</aside>
  </div>
  <footer class="border-t border-gray-200">Footer</footer>
</div>
```

Keep visual order consistent with DOM and focus order (WCAG 1.3.2, 2.4.3): put main content first in the DOM, place regions with grid lines or template areas, and reorder with `order-*` only when reading and tab order still make sense.

### Grid Template Areas

```css
@utility grid-areas-dashboard {
  grid-template-areas:
    "header header header"
    "nav main aside"
    "nav footer footer";
}

@utility area-header { grid-area: header; }
@utility area-nav { grid-area: nav; }
@utility area-main { grid-area: main; }
@utility area-aside { grid-area: aside; }
@utility area-footer { grid-area: footer; }
```

```html
<div class="grid grid-areas-dashboard grid-cols-[200px_1fr_250px] grid-rows-[60px_1fr_40px] min-h-dvh">
  <header class="area-header border-b border-gray-200">Header</header>
  <nav class="area-nav bg-gray-100">Navigation</nav>
  <main class="area-main p-6">Main Content</main>
  <aside class="area-aside bg-gray-50 p-4">Sidebar</aside>
  <footer class="area-footer bg-gray-800 text-white">Footer</footer>
</div>
```

### Auto-Fill and Auto-Fit Grids

```html
<!-- Auto-fill: Creates as many tracks as fit, even empty ones -->
<div class="grid grid-cols-[repeat(auto-fill,minmax(250px,1fr))] gap-6">
  <div class="rounded-lg border border-gray-200 p-4">Card 1</div>
  <div class="rounded-lg border border-gray-200 p-4">Card 2</div>
  <div class="rounded-lg border border-gray-200 p-4">Card 3</div>
</div>

<!-- Auto-fit: Collapses empty tracks -->
<div class="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-6">
  <!-- Cards stretch to fill available space -->
</div>

<!-- With arbitrary values -->
<div class="grid grid-cols-[repeat(auto-fill,minmax(min(100%,300px),1fr))] gap-4">
  <!-- Handles edge case where container is smaller than minmax min -->
</div>
```

### Subgrid

v4 includes `grid-cols-subgrid` and `grid-rows-subgrid`; do not redefine them.

```html
<div class="grid grid-cols-4 gap-4">
  <!-- Spans 2 columns; children align to the parent's column tracks -->
  <div class="col-span-2 grid grid-cols-subgrid">
    <div>Aligned to parent column 1</div>
    <div>Aligned to parent column 2</div>
  </div>
</div>

<!-- Card rows: title, body, and footer line up across sibling cards -->
<div class="grid grid-cols-3 grid-rows-[auto_1fr_auto] gap-x-4">
  <article class="row-span-3 grid grid-rows-subgrid gap-2 rounded-lg border border-gray-200 p-4">
    <h3>Title</h3>
    <p>Body of varying length</p>
    <a href="#">Read more</a>
  </article>
  <!-- more cards -->
</div>
```

## Advanced Flexbox Patterns

### Space Distribution

```html
<!-- Equal spacing with first/last at edges -->
<div class="flex justify-between">
  <div>First</div>
  <div>Second</div>
  <div>Third</div>
</div>

<!-- Equal space around each item (edge gaps are half the inner gaps) -->
<div class="flex justify-around">
  <div>Item</div>
  <div>Item</div>
  <div>Item</div>
</div>

<!-- Equal spacing between items and edges -->
<div class="flex justify-evenly">
  <div>Item</div>
  <div>Item</div>
  <div>Item</div>
</div>
```

### Flexible Item Sizing

```html
<!-- Items share space equally -->
<div class="flex">
  <div class="flex-1">1/3</div>
  <div class="flex-1">1/3</div>
  <div class="flex-1">1/3</div>
</div>

<!-- First item takes 2x space -->
<div class="flex">
  <div class="flex-[2]">2/4</div>
  <div class="flex-1">1/4</div>
  <div class="flex-1">1/4</div>
</div>

<!-- Fixed + flexible -->
<div class="flex">
  <div class="w-64 shrink-0">Fixed 256px</div>
  <div class="flex-1 min-w-0">Flexible (can shrink)</div>
</div>

<!-- Prevent shrinking with text overflow -->
<div class="flex min-w-0">
  <div class="shrink-0">Icon</div>
  <div class="min-w-0 truncate">Very long text that should truncate</div>
</div>
```

### Masonry-Like with Flexbox

```html
<!-- Column-based masonry -->
<div class="flex flex-col flex-wrap h-[800px] gap-4">
  <div class="w-[calc(33.333%-1rem)] h-48">Item 1</div>
  <div class="w-[calc(33.333%-1rem)] h-64">Item 2</div>
  <div class="w-[calc(33.333%-1rem)] h-32">Item 3</div>
  <!-- Items flow vertically then wrap to next column -->
</div>
```

## Container Queries

### Basic Container Queries

Container queries are built into v4; no plugin is needed.

```html
<!-- Define container -->
<div class="@container">
  <!-- Respond to container width -->
  <div class="flex flex-col @md:flex-row @lg:grid @lg:grid-cols-3 gap-4">
    <div>Item 1</div>
    <div>Item 2</div>
    <div>Item 3</div>
  </div>
</div>

<!-- Max-width and range queries -->
<div class="@container">
  <div class="grid grid-cols-3 @max-md:grid-cols-1 @min-[400px]:@max-xl:gap-6">...</div>
</div>
```

### Named Containers

```html
<!-- Multiple named containers -->
<div class="@container/sidebar">
  <nav class="flex flex-col @md/sidebar:flex-row">
    Navigation
  </nav>
</div>

<!-- prose-* classes require the @tailwindcss/typography plugin -->
<div class="@container/main">
  <article class="prose @min-[600px]/main:prose-lg @min-[900px]/main:prose-xl">
    Content
  </article>
</div>
```

### Container Query Units

```html
<!-- Size relative to container -->
<div class="@container">
  <h1 class="text-[5cqw]">Scales with container width</h1>
  <p class="text-[3cqi]">Scales with container inline size</p>
</div>
```

## Position and Layering

### Sticky Positioning

```html
<!-- Sticky header -->
<header class="sticky top-0 z-50 bg-white/80 backdrop-blur-sm border-b">
  Navigation
</header>

<!-- Sticky sidebar -->
<aside class="sticky top-20 h-[calc(100vh-5rem)] overflow-auto">
  Sidebar content
</aside>

<!-- Sticky table header -->
<div class="overflow-auto max-h-96">
  <table>
    <thead class="sticky top-0 bg-white">
      <tr>
        <th class="sticky left-0 bg-white z-10">Corner cell</th>
        <th>Column 2</th>
      </tr>
    </thead>
    <tbody>...</tbody>
  </table>
</div>
```

### Fixed Elements

```html
<!-- Fixed bottom navigation (mobile) -->
<nav class="fixed bottom-0 inset-x-0 z-50 bg-white border-t md:hidden">
  <div class="flex justify-around py-2">
    <a href="#">Home</a>
    <a href="#">Search</a>
    <a href="#">Profile</a>
  </div>
</nav>

<!-- Fixed action button -->
<button type="button" aria-label="New item" class="fixed right-6 bottom-6 z-40 rounded-full bg-brand-500 p-4 text-white shadow-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500">
  <svg aria-hidden="true" class="size-6">...</svg>
</button>
```

### Z-Index Management

`z-*` is a core utility namespace, so do not define `@utility z-modal`. Keep a layer scale in plain CSS variables and consume it with the `z-(--var)` shorthand:

```css
:root {
  --z-dropdown: 100;
  --z-sticky: 200;
  --z-modal: 500;
  --z-toast: 800;
}
```

```html
<header class="sticky top-0 z-(--z-sticky)">...</header>
<div role="dialog" class="fixed inset-0 z-(--z-modal)">...</div>
```

## Overflow and Scrolling

### Custom Scrollbars

Pseudo-elements are nested inside `@utility`; they cannot be part of the utility name.

To hide scrollbars, use `scrollbar-hide`, defined in v4-custom-utilities.md.

```css
@utility scrollbar-thin {
  scrollbar-width: thin;
}

@utility scrollbar-custom {
  scrollbar-color: var(--color-gray-400) var(--color-gray-100);
  &::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }
  &::-webkit-scrollbar-track {
    background: var(--color-gray-100);
  }
  &::-webkit-scrollbar-thumb {
    background: var(--color-gray-400);
    border-radius: 4px;
  }
  &::-webkit-scrollbar-thumb:hover {
    background: var(--color-gray-500);
  }
}
```

Chromium ignores the `::-webkit-scrollbar` rules when `scrollbar-color` or `scrollbar-width` is set, so the standard properties are the primary styling and the pseudo-elements are a fallback for older WebKit.

### Scroll Snap

```html
<!-- Horizontal carousel -->
<div class="flex snap-x snap-mandatory overflow-x-auto gap-4 pb-4">
  <div class="snap-start shrink-0 w-80">Card 1</div>
  <div class="snap-start shrink-0 w-80">Card 2</div>
  <div class="snap-start shrink-0 w-80">Card 3</div>
</div>

<!-- Full-page sections -->
<div class="h-screen snap-y snap-mandatory overflow-y-auto">
  <section class="h-screen snap-start">Section 1</section>
  <section class="h-screen snap-start">Section 2</section>
  <section class="h-screen snap-start">Section 3</section>
</div>

<!-- Snap with padding -->
<div class="snap-x scroll-pl-6 overflow-x-auto">
  <div class="snap-start">...</div>
</div>
```

### Scroll Margin for Anchors

```html
<!-- Offset for fixed header -->
<section id="about" class="scroll-mt-20">
  <!-- Content appears below fixed header when linked -->
</section>
```

## Aspect Ratio and Object Fit

### Responsive Aspect Ratios

```html
<!-- Fixed aspect ratio container -->
<div class="aspect-video bg-gray-100">
  <video class="h-full w-full object-cover">...</video>
</div>

<div class="aspect-square rounded-full overflow-hidden">
  <img src="avatar.jpg" alt="Profile photo of Jane Doe" class="h-full w-full object-cover" />
</div>

<!-- Custom aspect ratio -->
<div class="aspect-4/3">4:3 content</div>
<div class="aspect-21/9">Ultra-wide content</div>
```

### Object Positioning

```html
<!-- Focus on specific part of image -->
<div class="h-64 overflow-hidden">
  <img
    src="portrait.jpg"
    alt="Portrait of the team lead"
    class="h-full w-full object-cover object-top"
  />
</div>

<!-- Arbitrary object position -->
<img class="object-cover object-[25%_75%]" src="..." alt="" />
```

## Advanced Spacing

### Logical Properties

```html
<!-- Works for LTR and RTL -->
<div class="ps-4 pe-6 ms-auto">
  Padding and margin that respect text direction
</div>

<!-- Block direction (vertical in horizontal writing modes); pbs-*/pbe-*/mbs-*/mbe-* are v4.2+ -->
<div class="pbs-4 pbe-6 mbs-auto">
  Block-direction spacing
</div>
```

### Space Between with Dividers

```html
<!-- Dividers between items -->
<ul class="divide-y divide-gray-200">
  <li class="py-4">Item 1</li>
  <li class="py-4">Item 2</li>
  <li class="py-4">Item 3</li>
</ul>

<!-- Horizontal dividers -->
<div class="flex divide-x divide-gray-200">
  <div class="px-4">Section 1</div>
  <div class="px-4">Section 2</div>
  <div class="px-4">Section 3</div>
</div>
```

### Negative Margins for Bleeds

```html
<!-- Full-bleed image in padded container; max-w-none overrides preflight img { max-width: 100% } -->
<article class="px-6">
  <p>Padded content</p>
  <img src="hero.jpg" alt="" class="-mx-6 w-[calc(100%+3rem)] max-w-none" />
  <p>More padded content</p>
</article>

<!-- Pull quote that breaks out; negative margin matches the container padding at each breakpoint -->
<div class="max-w-prose mx-auto px-4 md:px-16">
  <p>Normal content...</p>
  <blockquote class="-mx-4 px-4 md:-mx-16 md:px-16 py-8 bg-gray-100">
    Featured quote that extends beyond content width
  </blockquote>
</div>
```

## Multi-Column Layout

### Text Columns

```html
<!-- Responsive columns -->
<div class="columns-1 sm:columns-2 lg:columns-3 gap-8">
  <p>Content flows across columns...</p>
</div>

<!-- Fixed-width columns -->
<div class="columns-[300px] gap-6">
  <p>Creates as many 300px columns as fit</p>
</div>

<!-- Prevent breaks inside elements -->
<div class="columns-2">
  <div class="break-inside-avoid mb-4">
    Card that stays together
  </div>
</div>
```

## Responsive Patterns

### Container Queries + Media Queries

```html
<div class="@container">
  <!-- @md: reacts to the container width; lg: reacts to the viewport -->
  <div class="@md:flex @md:gap-4 lg:grid lg:grid-cols-2">
    Content
  </div>
</div>
```

### Breakpoint-Based Visibility

```html
<!-- Show different content per breakpoint -->
<nav>
  <!-- Mobile menu button -->
  <button class="md:hidden">Menu</button>

  <!-- Desktop navigation -->
  <ul class="hidden md:flex gap-4">
    <li>Home</li>
    <li>About</li>
    <li>Contact</li>
  </ul>
</nav>
```

### Fluid Sizing with Clamp

```html
<!-- Fluid padding -->
<section class="py-[clamp(2rem,5vw,6rem)] px-[clamp(1rem,3vw,4rem)]">
  Content with responsive padding
</section>

<!-- Fluid max-width -->
<div class="mx-auto w-full max-w-[clamp(300px,90vw,1200px)]">
  Responsive container
</div>
```

## Print Styles

```html
<!-- Hide elements when printing -->
<nav class="print:hidden">Navigation</nav>

<!-- Show only when printing -->
<div class="hidden print:block">Print-only content</div>

<!-- Print-specific styles -->
<article class="print:text-black print:bg-white">
  <h1 class="text-2xl print:text-xl">Heading</h1>
  <a href="..." class="text-blue-500 print:text-black print:underline">
    Link (shows as text when printed)
  </a>
</article>

<!-- Prevent page breaks -->
<div class="print:break-inside-avoid">
  Keep this content together on one page
</div>

<!-- Force page break -->
<div class="print:break-before-page">
  Start on new page
</div>
```

## Best Practices

### 1. Use Modern Layout Methods

```html
<!-- Prefer Grid for 2D layouts -->
<div class="grid grid-cols-3 gap-4">

<!-- Prefer Flexbox for 1D layouts -->
<div class="flex items-center gap-2">
```

### 2. Handle Edge Cases

```html
<!-- Prevent flex item from overflowing -->
<div class="flex min-w-0">
  <div class="min-w-0 truncate">Long text</div>
</div>

<!-- Prevent grid blowout -->
<div class="grid grid-cols-1 min-w-0">
  <div class="overflow-hidden">Content that might overflow</div>
</div>
```

### 3. Use Semantic Sizing

```html
<!-- Prefer max-w-prose for reading content -->
<article class="max-w-prose mx-auto">

<!-- Use container for page sections -->
<div class="container mx-auto px-4">
```

### 4. Test All Breakpoints

Check each layout at every breakpoint the project defines and at widths between them, plus with long content and at 200% zoom.
