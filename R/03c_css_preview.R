# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== CRITICAL: Table starts at width 0 and grows only to fit content ===== */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: 0 !important;
    min-width: 0 !important;
    table-layout: auto !important;
  }

  /* All cells: no explicit width, just shrink to content */
  #tbl_preview th,
  #tbl_preview td {
    width: auto !important;
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Wrapper: shrink-wrap around table */
  #tbl_preview_wrapper {
    width: 0 !important;
    min-width: 0 !important;
    display: table !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
  }

  /* Sort row and filter row cells */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview thead tr.dt-filter-row th {
    width: auto !important;
    white-space: nowrap !important;
  }

  /* Filter inputs: small and compact */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: 50px !important;
    min-width: 30px !important;
    max-width: 80px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    white-space: nowrap !important;
    width: auto !important;
  }

  /* FixedHeader clone must match */
  .fixedHeader-floating#tbl_preview th,
  .fixedHeader-floating table#tbl_preview th {
    width: auto !important;
    white-space: nowrap !important;
  }

</style>
"
)
