# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== CRITICAL: Table as inline-table to shrink to content ===== */
  #tbl_preview,
  #tbl_preview.dataTable {
    display: inline-table !important;
    width: auto !important;
    max-width: none !important;
    min-width: 0 !important;
    table-layout: auto !important;
  }

  /* All cells: auto width, shrink to content */
  #tbl_preview th,
  #tbl_preview td {
    width: auto !important;
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Wrapper: inline-block to shrink-wrap the table */
  #tbl_preview_wrapper {
    display: inline-block !important;
    width: auto !important;
    max-width: 100% !important;
    min-width: 0 !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
  }

  /* Card body: block layout, don't flex-stretch children */
  #tbl_preview_wrapper,
  #tbl_preview_wrapper > * {
    flex: none !important;
    align-self: flex-start !important;
  }

  /* Container elements - inline-block to shrink */
  #tbl_preview_wrapper .dataTables_scroll,
  #tbl_preview_wrapper .dataTables_scrollHead,
  #tbl_preview_wrapper .dataTables_scrollBody,
  #tbl_preview_wrapper .dataTables_scrollHeadInner {
    display: inline-block !important;
    width: auto !important;
    max-width: none !important;
  }

  /* Inner tables also inline-table */
  #tbl_preview_wrapper .dataTables_scrollHead table,
  #tbl_preview_wrapper .dataTables_scrollBody table {
    display: inline-table !important;
    width: auto !important;
  }

  /* Sort row and filter row cells - auto width */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview thead tr.dt-filter-row th {
    width: auto !important;
    white-space: nowrap !important;
  }

  /* Filter inputs: fill cell width, don't force it wider */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: 100% !important;
    min-width: 30px !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row - auto width */
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
