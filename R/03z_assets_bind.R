# R/03z_assets_bind.R — Bind CSS parts + JS parts and export final objects
# - Combines core CSS fragments into one tag bundle
# - Provides final CSS overrides for DT alignment & layout
# - Concatenates JS (core + advanced DT header)
# - Defines with_plotly_tools() to enable the native Plotly modebar (per your request)

# Compose the CSS parts into one tag bundle used by ui header
header_css <- htmltools::tagList(css_core, css_dt, css_preview)

# Keep a placeholder for future server-injected overrides
css_overrides <- htmltools::tags$style(htmltools::HTML("
/* ===== FINAL OVERRIDES: widths & header alignment ===== */

/* CRITICAL: All DataTables use inline-table to shrink to content */
table.dataTable {
  display: inline-table !important;
  width: auto !important;
  max-width: none !important;
  min-width: 0 !important;
  table-layout: auto !important;
}

/* All cells: auto width, nowrap */
table.dataTable th,
table.dataTable td {
  width: auto !important;
  white-space: nowrap !important;
}

/* Wrapper containers - inline-block to shrink */
div.dataTables_wrapper {
  display: inline-block !important;
  width: auto !important;
  max-width: 100% !important;
  min-width: 0 !important;
  flex: none !important;
  align-self: flex-start !important;
}

/* CRITICAL: Force header and body containers to inline-block */
div.dataTables_scrollHeadInner {
  display: inline-block !important;
  width: auto !important;
  max-width: none !important;
  min-width: 0 !important;
}
div.dataTables_scrollHeadInner > table.dataTable {
  display: inline-table !important;
  width: auto !important;
  max-width: none !important;
  min-width: 0 !important;
  margin: 0 !important;
}

/* Scroll containers - inline-block to shrink */
div.dataTables_scroll,
div.dataTables_scrollHead,
div.dataTables_scrollBody {
  display: inline-block !important;
  width: auto !important;
  max-width: none !important;
}

/* Inner tables: inline-table */
div.dataTables_scrollHead table.dataTable,
div.dataTables_scrollBody table.dataTable {
  display: inline-table !important;
  width: auto !important;
  table-layout: auto !important;
}

/* Filter inputs: fill their cell, don't force it wider */
table.dataTable thead tr.dt-filter-row input.dt-filter-input {
  width: 100% !important;
  min-width: 30px !important;
  max-width: 100% !important;
}

/* Avoid header-cell overflow causing unexpected expansion */
div.dataTables_scrollHead th,
div.dataTables_scrollBody th { overflow: hidden !important; }

/* Ensure label row wraps in ALL headers, including FixedHeader clones and scroll head */
.fixedHeader-floating table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row) th,
.fixedHeader-locked  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row) th,
div.dataTables_scrollHead table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
  white-space: normal !important;
  word-break: break-word !important;
  overflow-wrap: anywhere !important;
  line-height: 1.15 !important;
}

/* Box sizing consistency (prevents tiny padding mismatches from growing columns) */
table.dataTable, table.dataTable th, table.dataTable td {
  box-sizing: border-box !important;
}

/* Labels row: wrap; helper rows (chips/filters): nowrap */
table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row) th{
  white-space: normal !important;
  word-break: break-word !important;
  overflow-wrap: anywhere !important;
  line-height: 1.15 !important;
}
table.dataTable thead tr.dt-sort-row th,
table.dataTable thead tr.dt-filter-row th{
  white-space: nowrap !important;
}

/* CRITICAL: Ensure sort/filter rows inherit column widths from label row */
table.dataTable thead tr.dt-sort-row th,
table.dataTable thead tr.dt-filter-row th {
  padding: 3px 6px !important;
  vertical-align: bottom !important;
}

/* Force columns to sync between header and body */
div.dataTables_scrollHead col,
div.dataTables_scrollBody col {
  width: auto !important;
}

/* Right align ONLY headers marked by our class */
table.dataTable thead th.dt-head-right,
.fixedHeader-floating thead th.dt-head-right,
.fixedHeader-locked  thead th.dt-head-right{
  text-align: right !important;
}

/* CRITICAL: Right-align sort and filter rows for numeric columns */
/* Use text-align + float to preserve table-cell layout */
table.dataTable thead tr.dt-sort-row th.dt-col-right,
div.dataTables_scrollHead table.dataTable thead tr.dt-sort-row th.dt-col-right,
.fixedHeader-floating thead tr.dt-sort-row th.dt-col-right {
  text-align: right !important;
}
table.dataTable thead tr.dt-sort-row th.dt-col-right .dt-sortbox {
  float: right !important;
}
table.dataTable thead tr.dt-filter-row th.dt-col-right,
div.dataTables_scrollHead table.dataTable thead tr.dt-filter-row th.dt-col-right,
.fixedHeader-floating thead tr.dt-filter-row th.dt-col-right {
  text-align: right !important;
}

/* Numeric columns: shrink-to-fit, keep numbers on one line — BODY CELLS ONLY */
table.dataTable td.dt-numeric-cfit{
  width: 1% !important;
  white-space: nowrap !important;
}

/* Text columns: wrap & cap width to avoid bloat */
table.dataTable thead th.dt-head-wrap,
table.dataTable tbody td.dt-wrap{
  white-space: normal !important;
  word-break: break-word !important;
  overflow-wrap: anywhere !important;
  max-width: 260px;
}

/* Hide ALL native sort icons (old+new DT classnames) */
table.dataTable thead > tr > th.sorting,
table.dataTable thead > tr > th.sorting_asc,
table.dataTable thead > tr > th.sorting_desc,
table.dataTable thead > tr > td.sorting,
table.dataTable thead > tr > td.sorting_asc,
table.dataTable thead > tr > td.sorting_desc,
table.dataTable thead > tr > th.dt-orderable,
table.dataTable thead > tr > th.dt-ordering-asc,
table.dataTable thead > tr > th.dt-ordering-desc,
table.dataTable thead > tr > td.dt-orderable,
table.dataTable thead > tr > td.dt-ordering-asc,
table.dataTable thead > tr > td.dt-ordering-desc{
  background-image: none !important;
  background: none !important;
  padding-right: 8px !important;
}
table.dataTable thead .sorting:before,
table.dataTable thead .sorting:after,
table.dataTable thead .sorting_asc:before,
table.dataTable thead .sorting_asc:after,
table.dataTable thead .sorting_desc:before,
table.dataTable thead .sorting_desc:after,
table.dataTable thead .dt-orderable:before,
table.dataTable thead .dt-orderable:after,
table.dataTable thead .dt-ordering-asc:before,
table.dataTable thead .dt-ordering-asc:after,
table.dataTable thead .dt-ordering-desc:before,
table.dataTable thead .dt-ordering-desc:after{
  content: none !important;
  display: none !important;
}
"))

# Concatenate JS parts into a single string consumed by ui.R
js_code <- paste(js_core, js_dt, sep = "\n")

# Plotly helper (native modebar with the exact tools you want kept)
with_plotly_tools <- function(p) {
  p %>%
    plotly::layout(
      # sensible interactive defaults
      dragmode = "zoom",
      hovermode = "closest",
      xaxis = list(showspikes = TRUE, spikemode = "across", spikesnap = "cursor"),
      yaxis = list(showspikes = TRUE, spikemode = "across", spikesnap = "cursor")
    ) %>%
    plotly::config(
      displayModeBar = TRUE,
      displaylogo    = FALSE,
      scrollZoom     = TRUE,   # wheel zoom
      doubleClick    = "reset",
      responsive     = TRUE,
      
      # Remove only the junk/irrelevant buttons; KEEP all core 2D tools:
      #   zoom2d, pan2d, zoomIn2d, zoomOut2d, autoScale2d, resetScale2d,
      #   select2d, lasso2d, toImage, toggleSpikelines,
      #   hoverClosestCartesian, hoverCompareCartesian, toggleLegend
      modeBarButtonsToRemove = list(
        # cloud / web editor / legacy hover layer
        "sendDataToCloud", "editInChartStudio", "plotly_hover_layer",
        # 3D camera/orbit/reset
        "resetViews", "resetCameraDefault3d", "resetCameraLastSave3d",
        "orbitRotation", "tableRotation", "orbit3d", "pan3d", "zoom3d",
        # GL / Pie / Geo hover or zoom tools (not used in these charts)
        "hoverClosest3d", "hoverClosestGl2d", "hoverClosestPie",
        "zoomInGeo", "zoomOutGeo", "resetGeo", "hoverClosestGeo"
        # NOTE: do NOT remove hoverClosestCartesian / hoverCompareCartesian or toggleSpikelines
      ),
      
      # PNG export settings (camera icon)
      toImageButtonOptions = list(
        format   = "png",
        filename = "plotly_chart",
        height   = 600,
        width    = 900,
        scale    = 2
      )
    )
}
