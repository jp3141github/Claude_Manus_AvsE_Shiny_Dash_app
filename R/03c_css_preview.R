# R/03c_css_preview.R — Input Data preview-specific styling

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Data cells - no wrapping ===== */
  #tbl_preview td,
  #tbl_preview_wrapper .dataTables_scrollBody td {
    white-space: nowrap !important;
    padding: 2px 4px !important;
  }

  /* ===== Header cells - no wrapping ===== */
  #tbl_preview thead th,
  #tbl_preview_wrapper .dataTables_scrollHead thead th {
    white-space: nowrap !important;
    padding: 2px 4px !important;
  }

  /* ===== Sort row ===== */
  #tbl_preview thead tr.dt-sort-row th .dt-sortbox,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr.dt-sort-row th .dt-sortbox {
    display: inline-block !important;
    width: auto !important;
  }

  /* ===== Filter row ===== */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input,
  #tbl_preview_wrapper .dataTables_scrollHead thead tr.dt-filter-row input.dt-filter-input {
    width: auto !important;
    min-width: 20px !important;
    box-sizing: border-box !important;
    padding: 1px 2px !important;
    height: 18px !important;
    font-size: 10px !important;
  }

</style>
"
)
