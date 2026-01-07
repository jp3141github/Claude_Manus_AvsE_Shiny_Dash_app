# R/03b_css_dt.R — DataTables global visual styles (chips, filters, icons, wrapping)

css_dt <- htmltools::HTML(
  "
<style>
  /* ----- STRUCTURE -----
     top:    chips (dt-sort-row)
     middle: filters (dt-filter-row)
     bottom: labels row (real headers)
  -------------------------------- */

  /* Chips above label */
  th .dt-head-label { display:block; }
  thead tr:nth-child(1) th { vertical-align: bottom; }

  thead th .dt-sortbox { display:block; margin-bottom:4px; }
  .fixedHeader-floating thead th .dt-sortbox { display:block; margin-bottom:4px; }
  thead th { position:relative; vertical-align:bottom; }
  .dt-sortbox { display:inline-flex; align-items:center; gap:4px; }

  .dt-sortbtn {
    padding:0 6px;
    line-height:18px;
    height:20px;
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
  thead tr.dt-sort-row th.dt-col-right { text-align: right !important; }
  thead tr.dt-sort-row th.dt-col-right .dt-sortbox { justify-content: flex-end; }
  thead tr.dt-filter-row th.dt-col-right { text-align: right !important; }
  thead tr.dt-filter-row th.dt-col-right input.dt-filter-input { text-align: right; }

  /* Filter controls container - position above a specific column */
  .dt-filter-controls {
    display: inline-block;
    white-space: nowrap;
  }

  /* ----- FILTERS: much shorter, fixed visible width -----
     Users can type longer; input scrolls horizontally. */
  thead tr.dt-filter-row th { padding: 3px 6px !important; }
  thead tr.dt-filter-row input.dt-filter-input{
    width: 120px !important;     /* << shorter visible box */
    max-width: 120px !important;
    min-width: 0 !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
    overflow: hidden !important;  /* show only visible portion */
  }

  /* ----- LABEL WRAPPING (bottom row only) -----
     Chips + filters remain nowrap; labels wrap. */
  thead tr:not(.dt-sort-row):not(.dt-filter-row) th{
    white-space: normal !important;
    word-break: break-word !important;
    overflow-wrap: anywhere !important;
    line-height: 1.15 !important;
  }
  thead tr:not(.dt-sort-row):not(.dt-filter-row) th *{
    white-space: inherit !important;
    word-break: inherit !important;
    overflow-wrap: inherit !important;
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
  }
  /* Remove extra right padding reserved for icons */
  table.dataTable thead > tr > th.sorting,
  table.dataTable thead > tr > th.sorting_asc,
  table.dataTable thead > tr > th.sorting_desc{
    padding-right: 8px !important;
  }
</style>
"
)
