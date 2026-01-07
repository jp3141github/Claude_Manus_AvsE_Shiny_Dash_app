# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Let DataTables autoWidth handle column sizing ===== */
  /* Keep cells compact with no wrapping */
  #tbl_preview th,
  #tbl_preview td {
    white-space: nowrap !important;
    padding: 4px 8px !important;
  }

  /* Filter inputs - compact but usable */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: 100% !important;
    min-width: 40px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 22px !important;
    font-size: 11px !important;
  }

</style>
"
)
