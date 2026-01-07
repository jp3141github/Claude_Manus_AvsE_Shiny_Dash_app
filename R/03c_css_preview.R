# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== FORCE columns to shrink to content ===== */
  #tbl_preview th,
  #tbl_preview td {
    width: 1% !important;
    white-space: nowrap !important;
    padding: 2px 6px !important;
    box-sizing: border-box !important;
  }

  /* Table auto-sizes to content */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: auto !important;
    table-layout: auto !important;
  }

  /* Wrapper shrinks to table size */
  #tbl_preview_wrapper {
    width: auto !important;
    display: inline-block !important;
    max-width: 100% !important;
    overflow-x: auto !important;
  }

  /* Sort row */
  #tbl_preview thead tr.dt-sort-row th {
    width: 1% !important;
    white-space: nowrap !important;
    padding: 2px 6px !important;
  }
  #tbl_preview thead tr.dt-sort-row th .dt-sortbox {
    display: inline-flex !important;
    gap: 2px !important;
  }

  /* Filter row */
  #tbl_preview thead tr.dt-filter-row th {
    width: 1% !important;
    white-space: nowrap !important;
    padding: 2px 6px !important;
  }
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: 100% !important;
    min-width: 40px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 18px !important;
    font-size: 11px !important;
  }

  /* Label row (headers) */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    width: 1% !important;
    white-space: nowrap !important;
    padding: 2px 6px !important;
  }

</style>
"
)
