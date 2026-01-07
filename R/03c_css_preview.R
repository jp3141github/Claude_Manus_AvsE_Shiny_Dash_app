# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Data cells - no wrapping ===== */
  #tbl_preview td,
  #tbl_preview_wrapper .dataTables_scrollBody td {
    white-space: nowrap !important;
    padding: 2px 4px !important;
  }

  /* ===== Header label row - WRAP text (both original and scroll head) ===== */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    white-space: normal !important;
    word-wrap: break-word !important;
    max-width: 80px !important;
    padding: 2px 4px !important;
    vertical-align: bottom !important;
    line-height: 1.2 !important;
  }

  /* ===== Sort row - no wrapping ===== */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr.dt-sort-row th {
    white-space: nowrap !important;
    padding: 1px 2px !important;
  }
  #tbl_preview thead tr.dt-sort-row th .dt-sortbox,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr.dt-sort-row th .dt-sortbox {
    display: inline-block !important;
    width: auto !important;
  }

  /* ===== Filter row ===== */
  #tbl_preview thead tr.dt-filter-row th,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr.dt-filter-row th {
    white-space: nowrap !important;
    padding: 1px 2px !important;
  }
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr.dt-filter-row input.dt-filter-input {
    width: auto !important;
    min-width: 20px !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 1px 2px !important;
    height: 18px !important;
    font-size: 10px !important;
  }

</style>
"
)
