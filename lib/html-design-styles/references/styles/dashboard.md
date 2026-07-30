# Dashboard Style

Data-dense admin/analytics interface - sidebar navigation, metric cards, charts, tables, and a professional information-first aesthetic. Use when asked for "dashboard style".

## Typography

Inter (Google Fonts, weights 400-700). `font-medium` for headings. `font-normal text-sm` for body/labels. `font-mono` for numbers, IDs, and code values. `tracking-tight` on metric numbers.

## Colors

```
Background:    #f8fafc   (slate-50)
Sidebar bg:    #0f172a   (slate-900)
Surface:       #ffffff
Border:        #e2e8f0   (slate-200)
Text:          #1e293b   (slate-800)
Muted:         #64748b   (slate-500)
Primary:       #3b82f6   (blue-500)
Success:       #22c55e   (green-500)
Warning:       #f59e0b   (amber-500)
Danger:        #ef4444   (red-500)
```

## Layout

```css
.dashboard-layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  min-height: 100vh;
}
.sidebar { background: #0f172a; padding: 20px 0; }
.main-content { background: #f8fafc; padding: 24px; overflow-y: auto; }
```

## Sidebar

Dark left panel with logo at top. Nav items: `px-4 py-2.5 rounded-lg mx-2 text-sm font-medium`. Active: `bg-blue-600 text-white`. Inactive: `text-slate-400 hover:bg-slate-800 hover:text-white`. Section labels: `text-[10px] uppercase tracking-widest text-slate-500 px-4 py-2 mt-4`.

## Metric Cards

```css
.metric-card {
  background: white; border: 1px solid #e2e8f0;
  border-radius: 12px; padding: 20px;
}
/* Top: icon right-aligned in colored circle */
/* Middle: large number font-bold text-3xl font-mono */
/* Bottom: delta indicator (green up / red down arrow + %) */
```

## Delta Indicators

```css
.delta-up   { color: #22c55e; background: #f0fdf4; padding: 2px 8px; border-radius: 100px; font-size: 12px; font-weight: 600; }
.delta-down { color: #ef4444; background: #fef2f2; }
```

## Data Table

```css
table { width: 100%; border-collapse: collapse; }
thead { background: #f8fafc; border-bottom: 2px solid #e2e8f0; }
th { text-align: left; font-size: 11px; font-weight: 600; text-transform: uppercase; color: #64748b; letter-spacing: 0.05em; padding: 10px 16px; }
td { padding: 14px 16px; border-bottom: 1px solid #f1f5f9; font-size: 14px; }
tr:hover td { background: #f8fafc; }
```

## Status Badges

`border-radius: 100px; font-size: 11px; font-weight: 600; padding: 2px 10px`:
- Active: `bg-green-100 text-green-700`
- Pending: `bg-amber-100 text-amber-700`
- Error: `bg-red-100 text-red-700`
- Draft: `bg-slate-100 text-slate-600`

## Chart Placeholder

```css
.chart-container {
  background: white; border: 1px solid #e2e8f0; border-radius: 12px;
  padding: 20px;
  /* Header: title left, time-range pills right */
  /* Body: chart area (use CSS bars or SVG) */
}
.bar { background: #3b82f6; border-radius: 4px 4px 0 0; }
```

## Breadcrumb

`text-sm text-slate-400 font-medium` with `/` separator. Current page in `text-slate-900`.

## Implementation

- Google Fonts: Inter
- `antialiased`
- Sidebar fixed, main content scrollable
- Time-range pill group: `border border-slate-200 rounded-lg overflow-hidden` with `bg-blue-50 text-blue-600` for active pill
- Page header: title + subtitle + action buttons right-aligned
