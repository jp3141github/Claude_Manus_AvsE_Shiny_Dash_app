# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Dynamic column widths based on content ===== */
  /* Columns size to fit their header or data content (whichever is wider) */
  #tbl_preview th,
  #tbl_preview td {
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Table uses auto layout for content-based column sizing */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: auto !important;
    table-layout: auto !important;
  }

  /* Wrapper allows horizontal scroll if table exceeds container */
  #tbl_preview_wrapper {
    width: auto !important;
    display: inline-block !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
  }

  /* Sort row and filter row cells use auto width */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview thead tr.dt-filter-row th {
    white-space: nowrap !important;
  }

  /* Filter inputs: auto width with reasonable bounds */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: auto !important;
    min-width: 40px !important;
    max-width: 150px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row keeps nowrap for clean headers */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    white-space: nowrap !important;
  }

  /* FixedHeader clone must match */
  .fixedHeader-floating#tbl_preview th,
  .fixedHeader-floating table#tbl_preview th {
    white-space: nowrap !important;
  }

</style>
"
)
