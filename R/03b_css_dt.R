# R/03b_css_dt.R — DataTables global visual styles (chips, filters, icons, wrapping)

css_dt <- htmltools::HTML(
  "
<style>
  /* ----- STRUCTURE -----
     top:    filters (dt-filter-row)
     bottom: labels row with sort chips on left (dt-label-row)
  -------------------------------- */

  /* Sort buttons inline with column header (on left) */
  thead th { position:relative; vertical-align:bottom; }
  .dt-sortbox { display:inline-flex; align-items:center; gap:2px; margin-right:6px; vertical-align:middle; }

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
    color:#444 !important;
  }

  .dt-sortbtn.active {
    background:#e9f2ff;
    border-color:#6aa0ff;
  }

  /* Force dark grey text for A / D / − buttons */
  thead .dt-sortbtn { color:#555 !important; }
  thead .dt-sortbtn.active { color:#333 !important; }

  /* Small numeric badge for multi-sort order (position number) */
  .dt-sortbtn .dt-badge {
    position:absolute; top:-8px; right:-8px;
    min-width:16px; height:16px; line-height:16px;
    background:#dc3545; color:#fff; border-radius:50%;
    font-size:11px; font-weight:bold; text-align:center; padding:0 4px;
    display:none;
    z-index: 10;
    box-shadow: 0 1px 3px rgba(0,0,0,0.3);
  }
  .dt-sortbtn.has-badge .dt-badge { display:inline-block; }
  .dt-sortbtn.active {
    background:#d4edda !important;
    border-color:#28a745 !important;
    font-weight: bold;
  }

  /* Keep filter row compact */
  thead tr.dt-filter-row th { white-space: nowrap !important; padding: 3px 6px !important; }

  /* Right-aligned columns: filter input text alignment */
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
  thead tr.dt-filter-row input.dt-filter-input{
    width: auto !important;
    min-width: 40px !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* ----- LABEL ROW (contains sort buttons + column names) ----- */
  thead tr.dt-label-row th {
    white-space: nowrap !important;
    vertical-align: bottom !important;
  }

  /* Clear sort link styling */
  .dt-clear-sort {
    vertical-align: middle;
  }

  /* ----- HIDE ALL BUILT-IN SORT ICONS (including pseudo-elements) ----- */
  table.dataTable thead > tr > th.sorting,
  table.dataTable thead > tr > th.sorting_asc,
  table.dataTable thead > tr > th.sorting_desc,
  table.dataTable thead > tr > td.sorting,
  table.dataTable thead > tr > td.sorting_asc,
  table.dataTable thead > tr > td.sorting_desc{
    background-image: none !important;
    background: none !important;
  }
  /* DataTables uses :before/:after triangles – kill them */
  table.dataTable thead .sorting:before,
  table.dataTable thead .sorting:after,
  table.dataTable thead .sorting_asc:before,
  table.dataTable thead .sorting_asc:after,
  table.dataTable thead .sorting_desc:before,
  table.dataTable thead .sorting_desc:after{
    display:none !important;
    content:none !important;
    opacity: 0 !important;
    visibility: hidden !important;
  }
  /* Remove extra right padding reserved for icons */
  table.dataTable thead > tr > th.sorting,
  table.dataTable thead > tr > th.sorting_asc,
  table.dataTable thead > tr > th.sorting_desc{
    padding-right: 8px !important;
  }

  /* Hide DataTables 2.x sort indicator element (dt-column-order) */
  table.dataTable thead .dt-column-order,
  table.dataTable thead span.dt-column-order {
    display: none !important;
    visibility: hidden !important;
    opacity: 0 !important;
    width: 0 !important;
    height: 0 !important;
  }

  /* Hide any sort icon elements (i tags, font icons) */
  table.dataTable thead th.sorting i,
  table.dataTable thead th.sorting_asc i,
  table.dataTable thead th.sorting_desc i,
  table.dataTable thead th.dt-orderable i {
    display: none !important;
    visibility: hidden !important;
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
