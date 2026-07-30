# Corporate Style

Conservative, structured, and trustworthy. Navy blues, clean grids, professional typography, and a buttoned-up B2B feel that communicates reliability above all. Use when asked for "corporate style".

## Typography

Source Sans 3 or IBM Plex Sans (Google Fonts, weights 300-700). No display fonts. `font-semibold` for headings, `font-normal` for body. `tracking-tight` on headings. Everything readable and measured.

## Colors

```
Background:  #ffffff
Surface:     #f8f9fc
Border:      #e4e7eb
Text:        #111827
Muted:       #6b7280
Navy:        #1e3a5f
Blue:        #2563eb
Light blue:  #eff6ff
Green:       #16a34a   (success/positive)
```

## Page Structure

Clean 3-zone layout: sticky nav → hero → alternating content sections → CTA → footer. No surprises. Max-width `max-w-7xl`.

## Cards

```css
.corp-card {
  background: white; border: 1px solid #e4e7eb;
  border-radius: 8px; padding: 24px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04);
}
.corp-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); transform: translateY(-2px); }
/* Blue left border on featured cards */
.corp-card-featured { border-left: 4px solid #2563eb; }
```

## Buttons

```css
.corp-btn {
  background: #2563eb; color: white;
  border-radius: 6px; border: none;
  font-weight: 600; font-size: 15px;
  padding: 12px 28px;
  box-shadow: 0 1px 2px rgba(37,99,235,0.3);
}
.corp-btn:hover { background: #1d4ed8; box-shadow: 0 4px 12px rgba(37,99,235,0.4); }
.corp-btn-outline { background: transparent; border: 1px solid #2563eb; color: #2563eb; border-radius: 6px; }
.corp-btn-navy { background: #1e3a5f; }
```

## Nav

`sticky top-0 bg-white border-b border-[#e4e7eb] shadow-sm`. Logo: navy text, clean. Links: `text-sm font-medium text-gray-600 hover:text-gray-900`. CTA: blue pill button. Professional and non-flashy.

## Feature Grid

3-column grid. Each card: small blue icon square `bg-blue-50 rounded-lg` + bold heading + muted body. No gimmicks - just clear value communication.

## Trust Signals

Client logos: `filter: grayscale(100%) opacity(0.5)` in a flex row. Testimonials: plain blockquote with name + title + company. Stats: large blue numbers, muted labels.

## CTA Section

Navy background `#1e3a5f`. White headline. Subtext in `text-blue-200`. White CTA button + blue outline secondary button.

## Implementation

- Google Fonts: IBM Plex Sans (300, 400, 600)
- `antialiased`
- `max-w-7xl mx-auto px-6`
- Section padding: `py-20`
- No playful elements - every choice communicates stability and professionalism
- Images: professional stock, desaturated slightly
