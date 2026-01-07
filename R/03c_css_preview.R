# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== CRITICAL: Force ALL cells to shrink to minimum content width ===== */
  /* The 1% width trick forces columns to be as narrow as possible */
  #tbl_preview th,
  #tbl_preview td {
    width: 1% !important;
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Table must use auto layout and not expand */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: auto !important;
    table-layout: auto !important;
  }

  /* Wrapper should not expand either */
  #tbl_preview_wrapper {
    width: auto !important;
    display: inline-block !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
  }

  /* Sort row and filter row cells also need 1% width */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview thead tr.dt-filter-row th {
    width: 1% !important;
    white-space: nowrap !important;
  }

  /* Filter inputs: shrink to content */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: auto !important;
    min-width: 30px !important;
    max-width: 120px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row can wrap if needed, but keep compact */
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

</style>
"
)
