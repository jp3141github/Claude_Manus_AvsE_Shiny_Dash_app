# R/03b_css_dt.R — DataTables global visual styles (chips, filters, icons, wrapping)

css_dt <- htmltools::HTML(
  "
<style>
  /* ----- STRUCTURE -----
     top:    controls (dt-controls-row) - apply/clear filters
     second: chips (dt-sort-row) - A/D/- buttons
     third:  filters (dt-filter-row)
     bottom: labels row (real headers) - with diamond sort icons on LEFT
  -------------------------------- */

  /* Controls row - minimal height, compact */
  thead tr.dt-controls-row th {
    padding: 2px 6px !important;
    white-space: nowrap !important;
    border-bottom: none !important;
  }

  /* Chips above label */
  th .dt-head-label { display:block; }
  thead tr:nth-child(1) th { vertical-align: bottom; }

  thead th .dt-sortbox { display:block; margin-bottom:4px; }
  .fixedHeader-floating thead th .dt-sortbox { display:block; margin-bottom:4px; }
  thead th { position:relative; vertical-align:bottom; }
  .dt-sortbox { display:inline-flex; align-items:center; gap:2px; }

  .dt-sortbtn {
    padding:0 4px;
    line-height:16px;
    height:18px;
    border:1px solid #ccc;
    border-radius:3px;
    background:#f7f7f7;
    cursor:pointer;
    user-select:none;
    font-size:11px;
    position: relative;
    color:#444 !important;   /* NEW → dark grey font instead of black */
  }

  .dt-sortbtn.active {
    background:#e9f2ff;
    border-color:#6aa0ff;
  }

  /* Force dark grey text for A / D / − buttons */
  thead tr.dt-sort-row th .dt-sortbtn { color:#555 !important; }  /* darker grey */
  thead tr.dt-sort-row th .dt-sortbtn.active { color:#333 !important; } /* slightly darker when active */

  /* Small numeric badge for multi-sort order (position number) */
  .dt-sortbtn .dt-badge {
    position:absolute; top:-8px; right:-8px;
    min-width:16px; height:16px; line-height:16px;
    background:#dc3545; color:#fff; border-radius:50%;
    font-size:11px; font-weight:bold; text-align:center; padding:0 4px;
    display:none;    /* hidden until used */
    z-index: 10;
    box-shadow: 0 1px 3px rgba(0,0,0,0.3);
  }
  .dt-sortbtn.has-badge .dt-badge { display:inline-block; }
  .dt-sortbtn.active {
    background:#d4edda !important;
    border-color:#28a745 !important;
    font-weight: bold;
  }

  /* Keep helper rows compact & on one line */
  thead tr.dt-sort-row th,
  thead tr.dt-filter-row th { white-space: nowrap !important; }
  thead tr.dt-sort-row th { padding: 3px 6px !important; }
  thead tr.dt-sort-row .dt-sortbox { display: inline-flex; gap: 4px; }

  /* Right-aligned columns: align sort buttons and filter to the right */
  /* Use text-align + float to preserve table-cell layout */
  thead tr.dt-sort-row th.dt-col-right {
    text-align: right !important;
  }
  thead tr.dt-sort-row th.dt-col-right .dt-sortbox {
    float: right !important;
  }
  thead tr.dt-filter-row th.dt-col-right {
    text-align: right !important;
  }
  thead tr.dt-filter-row th.dt-col-right input.dt-filter-input {
    text-align: right !important;
  }

  /* Filter controls container - position above a specific column */
  .dt-filter-controls {
    display: inline-block;
    white-space: nowrap;
  }

  /* ----- FILTERS: adapt to column width, not fixed ----- */
  thead tr.dt-filter-row th { padding: 3px 6px !important; }
  thead tr.dt-filter-row input.dt-filter-input{
    width: auto !important;
    min-width: 40px !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* ----- LABEL WRAPPING (bottom row only) -----
     Controls + Chips + filters remain nowrap; labels wrap. */
  thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) th{
    white-space: normal !important;
    word-break: break-word !important;
    overflow-wrap: anywhere !important;
    line-height: 1.15 !important;
  }
  thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) th *{
    white-space: inherit !important;
    word-break: inherit !important;
    overflow-wrap: inherit !important;
  }

  /* ----- DIAMOND SORT ICONS: Position on LEFT of column header text ----- */
  /* Remove background images (old DataTables style) */
  table.dataTable thead > tr > th.sorting,
  table.dataTable thead > tr > th.sorting_asc,
  table.dataTable thead > tr > th.sorting_desc,
  table.dataTable thead > tr > td.sorting,
  table.dataTable thead > tr > td.sorting_asc,
  table.dataTable thead > tr > td.sorting_desc{
    background-image: none !important;
    background: none !important;
  }

  /* Style the :before/:after triangles (diamond) and position on LEFT */
  /* Only show on label row, not on sort/filter/controls rows */
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) th.sorting,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) th.sorting_asc,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) th.sorting_desc {
    position: relative;
    padding-left: 22px !important;  /* Space for diamond on left */
    padding-right: 8px !important;
  }

  /* Position triangles on the LEFT */
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting:before,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting:after,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_asc:before,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_asc:after,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_desc:before,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_desc:after {
    position: absolute !important;
    display: block !important;
    content: "" !important;
    left: 6px !important;
    right: auto !important;
    opacity: 0.3;
    font-size: 10px;
    line-height: 1;
  }

  /* Up triangle (before) */
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting:before,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_asc:before,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_desc:before {
    content: '\\25B2' !important;
    bottom: 55% !important;
    top: auto !important;
  }

  /* Down triangle (after) */
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting:after,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_asc:after,
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_desc:after {
    content: '\\25BC' !important;
    top: 55% !important;
    bottom: auto !important;
  }

  /* Highlight active sort direction */
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_asc:before {
    opacity: 1 !important;
    color: #0d6efd !important;
  }
  table.dataTable thead tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row) .sorting_desc:after {
    opacity: 1 !important;
    color: #0d6efd !important;
  }

  /* Hide icons on helper rows (controls, sort, filter rows) */
  table.dataTable thead tr.dt-sort-row th:before,
  table.dataTable thead tr.dt-sort-row th:after,
  table.dataTable thead tr.dt-filter-row th:before,
  table.dataTable thead tr.dt-filter-row th:after,
  table.dataTable thead tr.dt-controls-row th:before,
  table.dataTable thead tr.dt-controls-row th:after {
    display: none !important;
    content: none !important;
  }

  /* ----- A-E VALUE COLORING (green for negative, red for positive) ----- */
  table.dataTable td.ae-negative {
    background-color: rgba(144, 238, 144, 0.4) !important;
    color: darkgreen !important;
  }
  table.dataTable td.ae-positive {
    background-color: rgba(255, 182, 182, 0.4) !important;
    color: darkred !important;
  }
</style>
"
)
