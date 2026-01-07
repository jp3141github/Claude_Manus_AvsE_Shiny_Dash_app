# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== CRITICAL: Force preview table wrapper to shrink to content ===== */
  #tbl_preview_wrapper {
    width: fit-content !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
    max-height: none !important;
    min-height: 0 !important;
    display: block !important;
  }

  /* The table itself must also shrink to content */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: auto !important;
    table-layout: auto !important;
    overflow: visible !important;
  }

  /* All cells: no wrapping, tight padding for natural column widths */
  #tbl_preview th,
  #tbl_preview td {
    white-space: nowrap !important;
    padding: 3px 6px !important;
    box-sizing: border-box !important;
  }

  /* Prevent card body from stretching the table wrapper */
  .card:has(#tbl_preview_wrapper) .card-body {
    display: block !important;
    width: auto !important;
  }

  /* Also target the card itself to not expand */
  .card:has(#tbl_preview_wrapper) {
    width: fit-content !important;
    max-width: 100% !important;
  }

  /* Fallback for browsers without :has() - target by structure */
  .nav-panel-content .card .card-body > #tbl_preview_wrapper,
  [role='tabpanel'] .card .card-body > #tbl_preview_wrapper {
    width: fit-content !important;
  }

  /* Horizontal scroll only */
  .auto-height-table .dataTables_scrollBody{
    overflow-x: auto !important; overflow-y: visible !important; height: auto !important; max-height: none !important;
  }

  /* Wrap the *labels row only* for preview table (chips/filters remain nowrap) */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th{
    white-space: normal !important; word-break: break-word !important; overflow-wrap: anywhere !important; line-height: 1.15 !important;
  }
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th *{
    white-space: inherit !important; word-break: inherit !important; overflow-wrap: inherit !important;
  }

  /* FixedHeader clone must match */
  .fixedHeader-floating#tbl_preview thead th,
  .fixedHeader-floating table#tbl_preview thead th{
    white-space: normal !important; word-break: break-word !important; overflow-wrap: anywhere !important; line-height: 1.15 !important;
  }

  /* Filter inputs: adapt to column width, not fixed */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input{
    width: auto !important;
    min-width: 40px !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

</style>
"
)
