# R/03c_css_preview.R — Input Data preview-specific header wrapping and layout

css_preview <- htmltools::HTML(
"
<style>
  /* Allow page scroll so FixedHeader can pin on preview */
  #tbl_preview_wrapper { overflow: visible !important; max-height: none !important; min-height: 0 !important; }

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

  /* Keep table layout stable with long headers */
  #tbl_preview{ overflow: visible !important; }
  #tbl_preview.dataTable, #tbl_preview table.dataTable{ table-layout: fixed !important; }
  #tbl_preview thead th{ max-width: 260px; }
  
  /* Preview: keep filter inputs compact & stable */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input{
    width: 120px !important;
    max-width: 120px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }
  
</style>
"
)
