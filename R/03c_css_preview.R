# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== CRITICAL: Table shrinks to fit content only ===== */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: fit-content !important;
    max-width: fit-content !important;
    min-width: 0 !important;
    table-layout: auto !important;
  }

  /* All cells: shrink to content, no stretching */
  #tbl_preview th,
  #tbl_preview td {
    width: 1% !important;        /* Shrink to content trick */
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Wrapper: shrink-wrap, don't stretch */
  #tbl_preview_wrapper {
    width: fit-content !important;
    max-width: 100% !important;
    min-width: 0 !important;
    display: block !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
    flex: 0 0 auto !important;   /* Don't stretch in flex container */
  }

  /* Container card should not stretch the table */
  #tbl_preview_wrapper .dataTables_scroll,
  #tbl_preview_wrapper .dataTables_scrollHead,
  #tbl_preview_wrapper .dataTables_scrollBody {
    width: fit-content !important;
    max-width: fit-content !important;
  }

  /* Sort row and filter row cells - shrink to content */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview thead tr.dt-filter-row th {
    width: 1% !important;
    white-space: nowrap !important;
  }

  /* Filter inputs: fill cell width, don't force it wider */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: 100% !important;      /* Fill the cell, don't force it wider */
    min-width: 30px !important;  /* Minimum readable size */
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row - shrink to content */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    white-space: nowrap !important;
    width: 1% !important;
  }

  /* FixedHeader clone must match */
  .fixedHeader-floating#tbl_preview th,
  .fixedHeader-floating table#tbl_preview th {
    width: 1% !important;
    white-space: nowrap !important;
  }

  /* Parent card body should not force stretch */
  .card:has(#tbl_preview_wrapper) .card-body {
    display: block !important;
    width: auto !important;
  }

</style>
"
)
