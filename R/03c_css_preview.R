# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* ===== Column widths based on header text (JS sets explicit widths) ===== */
  #tbl_preview th,
  #tbl_preview td {
    white-space: nowrap !important;
    padding: 3px 4px !important;
    box-sizing: border-box !important;
    overflow: hidden !important;
    text-overflow: ellipsis !important;
  }

  /* Table uses fixed layout - JS sets column widths */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: auto !important;
    table-layout: fixed !important;
  }

  /* Wrapper allows horizontal scroll if table exceeds container */
  #tbl_preview_wrapper {
    width: auto !important;
    display: inline-block !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
  }

  /* Sort row - compact with sortbox inline */
  #tbl_preview thead tr.dt-sort-row th {
    white-space: nowrap !important;
    overflow: visible !important;
    padding: 2px 4px !important;
  }

  /* Sortbox: compact inline-flex, no extra gaps */
  #tbl_preview thead tr.dt-sort-row th .dt-sortbox {
    display: inline-flex !important;
    gap: 2px !important;
    margin: 0 !important;
  }

  /* Filter row cells */
  #tbl_preview thead tr.dt-filter-row th {
    white-space: nowrap !important;
    overflow: visible !important;
    padding: 2px 4px !important;
  }

  /* Filter inputs: sized by JS to match header width */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row (headers) - compact padding */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    white-space: nowrap !important;
    padding: 3px 4px !important;
  }

  /* FixedHeader clone must match */
  .fixedHeader-floating#tbl_preview th,
  .fixedHeader-floating table#tbl_preview th {
    white-space: nowrap !important;
  }

</style>
"
)
