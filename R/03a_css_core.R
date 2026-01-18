# R/03a_css_core.R — Core (navbar, plots, busy overlay, DT wrappers)

css_core <- htmltools::HTML(
"
<style>
  /* =======================
     NAVBAR / HEADER THEME
     ======================= */
  .bslib-page-sidebar .navbar {
    background:#333 !important;
    border-bottom:2px solid #222 !important;
  }
  .bslib-page-sidebar .navbar .navbar-brand,
  .bslib-page-sidebar .navbar .navbar-nav .nav-link,
  .bslib-page-sidebar .navbar .navbar-text {
    color:#fff !important;
  }

  /* =======================
     PLOT CONTAINERS
     ======================= */
  .plot-wrap {
    position: relative;
    height: 100%;
    overflow: hidden;
  }
  .plot-wrap.is-fullscreen{
    position:fixed !important;
    z-index:5000 !important;
    inset:10px !important;
    background:#fff;
    padding:8px;
    height:calc(100vh - 20px) !important;
    width:calc(100vw - 20px) !important;
    box-shadow:0 0 0 9999px rgba(0,0,0,.35);
    transform:none !important;
    max-width:100% !important;
    max-height:100% !important;
    /* IMPORTANT for Plotly reflow while fullscreen */
    contain: none;
  }
  .plot-wrap.is-fullscreen .js-plotly-plot,
  .plot-wrap.is-fullscreen .plotly,
  .plot-wrap.is-fullscreen .html-widget {
    width:100% !important;
    height:calc(100vh - 50px) !important;
    max-width:100% !important;
  }

  /* Normal (non-fullscreen): fill the card's plot-wrap height */
  .plot-wrap .js-plotly-plot,
  .plot-wrap .plotly,
  .plot-wrap .html-widget {
    width: 100% !important;
    max-width: 100% !important;
    height: 100% !important;
    max-height: none !important;
  }

  /* Header tools on cards */
  .reset-btn { cursor: pointer; text-decoration: none; }
  .expand-btn { cursor: zoom-in; text-decoration: none; margin-left: .6ch; }
  .plot-wrap.is-fullscreen .expand-btn { cursor: zoom-out; }
  .reset-btn, .expand-btn { user-select: none; }

  body.body--no-scroll { overflow:hidden !important; }

  /* =======================
     DATATABLES: ALIGNMENT
     ======================= */
  table.dataTable .dt-right { text-align:right !important; }

  /* =======================
     BUSY OVERLAY
     ======================= */
  #busy-overlay {
    position:fixed;
    bottom:16px; right:16px;
    display:none;
    z-index:4000;
    pointer-events:none;
  }
  #busy-overlay.show { display:block; }
  #busy-overlay .spinner {
    width:28px; height:28px;
    border:4px solid #e9ecef;
    border-top-color:#000;
    border-radius:50%;
    animation:spin .8s linear infinite;
  }
  @keyframes spin { from {transform:rotate(0)} to {transform:rotate(360deg)} }

  /* =======================
     CHARTS LOADING OVERLAY
     ======================= */
  #charts_wait_wrap { position: relative; min-height: 80px; margin: 0 0 6px 0; }
  #charts_wait_msg {
    position: absolute; inset: 0;
    display: flex; align-items: center; justify-content: center;
    font-weight: 600; color: #666; text-align: center; line-height: 1.2;
  }

  /* ===== BULLETPROOF FULLSCREEN HOST ===== */
  #fs-host { position: fixed; inset: 0; z-index: 10050; display: none; }
  #fs-host.show { display: block; }
  #fs-host .fs-dimmer { position: absolute; inset: 0; background: rgba(0,0,0,.35); }
  #fs-host .fs-wrap {
    position: absolute; inset: 10px;
    background:#fff; box-shadow:0 0 0 1px rgba(0,0,0,.08), 0 10px 30px rgba(0,0,0,.25);
    overflow: hidden; display: flex;
  }
  #fs-host .fs-wrap .plot-wrap {
    flex: 1 1 auto; width: 100%; height: 100%;
    contain: none; /* allow Plotly reflow */
  }
  #fs-host .fs-close {
    position: absolute; top: 8px; right: 14px; z-index: 2;
    font-size: 13px; padding: 4px 8px; border-radius: 4px;
    background: rgba(255,255,255,.92); border: 1px solid #ccc;
    cursor: pointer; user-select: none;
  }

  /* Overlay host: make the expanded plot truly full height */
  #fs-host .fs-wrap .plot-wrap,
  #fs-host .fs-wrap .plot-wrap .js-plotly-plot,
  #fs-host .fs-wrap .plot-wrap .plotly,
  #fs-host .fs-wrap .plot-wrap .html-widget {
    height: calc(100vh - 24px) !important;   /* bigger usable area */
    max-height: calc(100vh - 24px) !important;
  }
  
  /* Fallback fullscreen (no overlay): make it taller than before */
  .plot-wrap.is-fullscreen .js-plotly-plot,
  .plot-wrap.is-fullscreen .plotly,
  .plot-wrap.is-fullscreen .html-widget {
    height: calc(100vh - 20px) !important;   /* was 50px margin; now taller */
  }

  /* =======================
     CARD SPACING
     ======================= */
  .bslib-card .card-body { padding: 8px; }
  @supports(selector(.card-body:has(.plotly.html-widget))) {
    .card-body:has(.plotly.html-widget) { padding: 5px !important; }
  }

  /* =======================
     LARGE DT WRAPPERS
     ======================= */
  /* Generic page area - NO vertical scroll, use pagination instead */
  #tabs_main .nav-content .bslib-card .dataTables_wrapper {
    min-height: 0 !important;
    max-height: none !important;
    overflow-y: visible !important;
  }

  /* === FROZEN HEADER WRAPPER ===
     Apply this class around DTOutput to enable vertical scrolling inside the table
     while keeping the header pinned (DataTables scrollY + FixedHeader).
  */
  .freeze-pane .dataTables_wrapper {
    min-height: 0 !important; height: auto !important;
    max-height: none !important; overflow: hidden !important;
  }
  .freeze-pane .dataTables_scrollBody {
    overflow-y: auto !important;
    overflow-x: auto !important;
    height: 60vh !important;
    max-height: 60vh !important;
  }
  .freeze-pane .dataTables_scrollHead {
    overflow: visible !important;
    border-bottom: none !important;  /* Remove duplicate border - keep only thead tr:last-child th border */
  }
  .freeze-pane table.dataTable {
    width: auto !important;
    table-layout: auto !important;
  }
  /* Remove duplicate top border on body table */
  .freeze-pane .dataTables_scrollBody table.dataTable {
    border-top: none !important;
  }
  /* Ensure header and body tables stay aligned */
  .freeze-pane .dataTables_scroll {
    overflow: visible !important;
  }

  /* === LEGACY: auto-height tables (no inner scrollbars) ===
     Used where we want the table to grow naturally with the card (e.g., Checks).
  */
  .auto-height-table .dataTables_wrapper { min-height: 0 !important; height: auto !important; max-height: none !important; overflow: visible !important; }
  .auto-height-table .dataTables_scrollBody { overflow: visible !important; height: auto !important; max-height: none !important; }
  .auto-height-table table.dataTable { width: 100% !important; }

  /* When DT is inside .auto-height-table inside main tab area */
  #tabs_main .nav-content .bslib-card .auto-height-table .dataTables_wrapper { min-height: 0 !important; max-height: none !important; overflow: visible !important; }
  #tabs_main .nav-content .bslib-card .auto-height-table .dataTables_scrollBody { height: auto !important; max-height: none !important; overflow: visible !important; }

  /* FixedHeader above cards/navbars */
  .fixedHeader-floating, .fixedHeader-locked { z-index: 1040 !important; }

  /* =======================
     FILE INPUT (Browse) STYLE
     ======================= */
  #csv_file .btn,
  #csv_file .btn:hover,
  #csv_file .btn:focus,
  #csv_file .btn:active,
  #csv_file .btn:visited,
  #csv_file .btn:focus-visible {
    background-color:#000 !important;
    color:#fff !important;
    border-color:#000 !important;
    box-shadow:none !important;
    outline:none !important;
  }
  #csv_file:not(.used) .btn { border:4px solid #D32F2F !important; }
  #csv_file.used .btn { border:2px solid #000 !important; }
  #csv_file_progress .progress-bar { background-color:#000 !important; }

  /* =======================
     RESULTS TAB: PCT TINT
     ======================= */
  #tabs_results_inner .nav-link[data-value='Class Summary pct'],
  #tabs_results_inner .nav-link[data-value='Class Peril Summary pct'] { background-color: #ffecec !important; }
  #tabs_results_inner .nav-link.active[data-value='Class Summary pct'],
  #tabs_results_inner .nav-link.active[data-value='Class Peril Summary pct'] {
    background-color: #ffdcdc !important; border-color: #f5b5b5 !important;
  }
</style>
"
)
