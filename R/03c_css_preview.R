# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Compact cells with no wrapping ===== */
  #tbl_preview th,
  #tbl_preview td {
    white-space: nowrap !important;
    padding: 2px 4px !important;
  }

  /* ===== Sort row - shrink to content ===== */
  #tbl_preview thead tr.dt-sort-row th {
    padding: 1px 2px !important;
  }
  #tbl_preview thead tr.dt-sort-row th .dt-sortbox {
    display: inline-block !important;
    width: auto !important;
  }

  /* ===== Filter row - inputs match column header width ===== */
  #tbl_preview thead tr.dt-filter-row th {
    padding: 1px 2px !important;
  }
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: auto !important;
    min-width: 20px !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 1px 2px !important;
    height: 18px !important;
    font-size: 10px !important;
  }

  /* ===== Remove ALL extra padding/margins from header cells ===== */
  #tbl_preview thead th {
    padding: 2px 4px !important;
    margin: 0 !important;
  }

</style>
"
)
