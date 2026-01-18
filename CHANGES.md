# ShinyDashAE v1.0.0 → v1.0.1 Changes

## Summary of Changes

This update adds **column filters** and **advanced multi-column sorting** to ALL DataTables in the application.

## Modified Files

### 1. `R/03e_js_dt_adv.R` - DataTables advanced header utilities

**Changes Made:**

1. **Removed `isPreview` restriction** (line 68)
   - Previously: Filter Apply/Clear buttons only appeared on the Input Data preview table
   - Now: Filter Apply/Clear buttons appear on ALL DataTables throughout the application

2. **Added Global DataTable Hook** (lines 396-409)
   - Added a `preInit.dt` event listener that automatically applies the advanced features to every DataTable when it initializes
   - This ensures all tables (Input Data, Results, Validation) get the same enhanced functionality

### 2. `R/60_ui_components.R` - UI components and JS helpers

**Changes Made:**

1. **Fixed JavaScript code overwrite bug** (lines 243-467)
   - Previously: `js_code` was being completely replaced, which removed the DataTable enhancements from `03z_assets_bind.R`
   - Now: The UI helper JavaScript is stored in `js_code_extra` and **appended** to the existing `js_code`

2. **Fixed JavaScript injection into UI** (lines 469-475)
   - Previously: The `ui` object was defined without including the JavaScript code
   - Now: The `ui` object is wrapped in a `tagList` that includes `css_overrides` and the `js_code` script tag
   - This ensures the JavaScript is actually loaded when the page renders

## Features Now Available on ALL Tables:

| Feature | Description |
|---------|-------------|
| **A/D/- Sort Buttons** | Each column has Ascending (A), Descending (D), and Neutral (-) sort buttons |
| **Multi-Sort with Priority** | When multiple columns are sorted, badges (1, 2, 3...) show the sort order |
| **Clear Sort Button** | "✖ clear" link to reset all sorting |
| **Column Filters** | Per-column text filter inputs with OR support (`;`) and wildcards (`*`, `?`, `%`) |
| **Apply Filters Button** | "✔ apply" link to apply all column filters at once |
| **Clear Filters Button** | "✖ clear filters" link to reset all column filters |
| **Page Jumper** | "Jump to [page]" input near pagination controls |

## How Sorting Works:

1. Click **A** on a column to sort ascending
2. Click **D** on a column to sort descending  
3. Click **-** on a column to remove that column from the sort
4. When multiple columns are sorted, a badge shows the priority (1 = primary sort, 2 = secondary, etc.)
5. Sorts are applied in the order they were clicked
6. Click "✖ clear" to reset all sorting

## How Filtering Works:

1. Type in the filter input above any column
2. Press **Enter** to apply that single filter, OR
3. Click "✔ apply" to apply all column filters at once
4. Use semicolon (`;`) to filter for multiple values (OR logic): `NIG;DLI` matches rows containing "NIG" OR "DLI"
5. Click "✖ clear filters" to reset all filters

### Wildcard Support:

| Wildcard | Meaning | Example | Matches |
|----------|---------|---------|---------|
| `*` | Any characters (zero or more) | `CMOT*` | CMOT, CMOT_DLI, CMOT_NIG_ALL |
| `?` | Single character | `CM?T` | CMOT, CMAT, CMBT |
| `%` | Any characters (SQL-style, same as `*`) | `%DLI%` | CMOT_DLI, DLI_BICP, NIG_DLI_ALL |

**Combined examples:**
- `CMOT_*_ALL` - Matches CMOT_DLI_ALL, CMOT_NIG_ALL, etc.
- `*DLI*;*NIG*` - Matches rows containing "DLI" OR "NIG" anywhere
- `20??.1` - Matches 2001.1, 2002.1, 2023.1, etc.

## Session Persistence:

- Sort and filter states are maintained within the current browser session
- States are preserved when switching between tabs
- States reset when the page is refreshed or the browser is closed

## Bug Fixes in This Version

### Bug 1: JavaScript code overwrite
```r
# BEFORE (BUG): This completely replaced js_code
js_code <- "..."

# AFTER (FIXED): Store in separate variable and append
js_code_extra <- "..."
js_code <- paste(js_code, js_code_extra, sep = "\n")
```

### Bug 2: JavaScript not injected into UI

```r
# BEFORE (BUG): ui defined without JavaScript
ui <- page_sidebar(...)

# AFTER (FIXED): Wrap ui to include JavaScript
ui <- htmltools::tagList(
  ui,
  css_overrides,
  tags$script(htmltools::HTML(js_code))
)
```