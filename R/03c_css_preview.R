# R/03c_css_preview.R — Input Data table styling (widths controlled by JS)

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Let JavaScript control column widths - don't override with CSS ===== */

  /* Wrapper: inline-block to shrink-wrap the table */
  #tbl_preview_wrapper {
    display: inline-block !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
    flex: none !important;
    align-self: flex-start !important;
  }

  /* All cells: nowrap, let JS set widths */
  #tbl_preview th,
  #tbl_preview td {
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Filter inputs: fill cell width */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: 100% !important;
    min-width: 30px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

</style>
"
)
