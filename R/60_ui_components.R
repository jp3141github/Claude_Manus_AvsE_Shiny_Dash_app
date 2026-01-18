# R/60_ui_components.R — UI component functions and styling

header_css <- HTML("
  <style>
    /* --- Add these new rules --- */
    /* Top navbar/banner for bslib page_sidebar */
    .bslib-page-sidebar .navbar {
      background: #333333 !important;   /* dark grey background */
      border-bottom: 2px solid #222 !important;
    }
    .bslib-page-sidebar .navbar .navbar-brand,
    .bslib-page-sidebar .navbar .navbar-nav .nav-link,
    .bslib-page-sidebar .navbar .navbar-text {
      color: #ffffff !important;         /* white text */
    }
    .bslib-page-sidebar .navbar .navbar-brand:hover,
    .bslib-page-sidebar .navbar .navbar-nav .nav-link:hover {
      color: #f2f2f2 !important;
    }
    /* --- End of new rules --- */
  .plot-wrap { position: relative; }
  .plot-wrap.is-fullscreen {
    position: fixed !important; z-index:2000 !important; inset:10px !important;
    background:#fff; padding:8px; height:calc(100vh - 20px) !important; width:calc(100vw - 20px) !important;
    box-shadow:0 0 0 9999px rgba(0,0,0,.35); transform:none !important;
  }
 .plot-wrap.is-fullscreen .js-plotly-plot,
 .plot-wrap.is-fullscreen .plotly,
 .plot-wrap.is-fullscreen .html-widget {
   width: 100% !important;                 /* ensure full-width canvas */
   height: calc(100vh - 50px) !important;  /* fill viewport minus header padding */
   max-width: 100% !important;
 }
.expand-btn { cursor: zoom-in; text-decoration: none; }
.plot-wrap.is-fullscreen .expand-btn { cursor: zoom-out; }

  table.dataTable thead th.dt-right, table.dataTable tfoot th.dt-right,
  table.dataTable tbody td.dt-right { text-align:right !important; }

  /* bottom-right mini spinner */
  #busy-overlay { position:fixed; bottom:16px; right:16px; display:none; z-index:4000; pointer-events:none; }
  #busy-overlay.show { display:block; }
  #busy-overlay .spinner {
    width:28px; height:28px; border:4px solid #e9ecef; border-top-color:#000;
    border-radius:50%; animation:spin .8s linear infinite;
  }
  @keyframes spin { from {transform:rotate(0)} to {transform:rotate(360deg)} }
  </style>
")

app_header <- tags$header(
  tags$div(
    tags$div(HTML("<b style='color:blue;'>AvE Analysis</b>"), class = "app-title")
  ),
  class = "app-header"
)

# ---- Assistant UI (HYBRID; include only if ENABLE_ASSISTANT) ----
# NOTE: Help button removed per user request - functionality still available via Ctrl/Cmd+K
assistant_button <- NULL
assistant_modal  <- NULL
if (ENABLE_ASSISTANT) {
  # Help button removed - assistant still accessible via Ctrl/Cmd+K keyboard shortcut
  assistant_button <- NULL  # Was: tags$button("❓ Help", id = "assist_open", class = "assist-fab")
  assistant_modal  <- modalDialog(
    tags$div(
      h4("Assistant"),
      p("Quick actions (", tags$span("Ctrl/Cmd+K", class = "assist-kbd"), " or ", tags$span("/", class = "assist-kbd"), " to open)"),
      textInput("assist_search", NULL, placeholder = "Type a command or question…", width = "100%"),
      fluidRow(
        column(6, bslib::card(
          bslib::card_header("Quick actions"),
          div(
            actionButton("assist_run", "▶ Run analysis", class = "btn btn-primary me-2"),
            actionButton("assist_clear", "🗑 Clear selections", class = "btn btn-outline-secondary me-2"),
            actionButton("assist_zip", "⬇ Download ZIP", class = "btn btn-outline-secondary me-2"),
            actionButton("assist_xlsx", "⬇ Download Excel", class = "btn btn-outline-secondary")
          )
        )),
        column(6, bslib::card(
          bslib::card_header("FAQ"),
          div(
            tags$details(tags$summary("What columns are required?"),
                         p("At minimum: Model Type, ProjectionDate, Actual, Expected, Accident Year, Product, Peril, Segment, Event / Non-Event, Section, ObjectName, Current or Prior.")),
            tags$details(tags$summary("Where do charts go?"),
                         p("Desktop: timestamped folder on disk. Browser: bundled inside ZIP and shown on 'Charts' tab."))
          )
        ))
      )
    ),
    id = "assist_modal", easyClose = TRUE, footer = NULL, size = "l", class = "assist-modal"
  )
}

# ---- UI helpers for expandable charts (same as first script) ----
expand_btn <- function(target_id) {
  tags$a("⤢ Expand", href = "#",
         class = "expand-btn float-end small text-muted",
         `data-target` = paste0(target_id, "_wrap"),
         style = "text-decoration:none;")
}

# Chart download buttons helper
chart_download_btns <- function(outputId) {
  tagList(
    tags$div(
      class = "btn-group btn-group-sm float-end me-2",
      role = "group",
      style = "margin-top: -4px;",
      downloadButton(
        outputId = paste0(outputId, "_download_png"),
        label = "PNG",
        class = "btn btn-outline-secondary btn-sm",
        style = "font-size: 11px; padding: 2px 8px;"
      ),
      downloadButton(
        outputId = paste0(outputId, "_download_csv"),
        label = "CSV",
        class = "btn btn-outline-secondary btn-sm",
        style = "font-size: 11px; padding: 2px 8px;"
      )
    )
  )
}

exp_card <- function(title, outputId, height = "300px") {
  bslib::card(
    bslib::card_header(tagList(
      title,
      chart_download_btns(outputId),
      expand_btn(outputId)
    )),
    div(id = paste0(outputId, "_wrap"),
        class = "plot-wrap",
        style = paste0("height:", height, ";"),
        plotlyOutput(outputId, height = "100%"))
  )
}

# ---- Sidebar (HYBRID) ----
sidebar_controls <- sidebar(
  h4("Analysis Controls"),
  fileInput("csv_file", "Upload CSV File",
            accept = c(".csv"), multiple = FALSE),
  actionButton("run_analysis", "Run Analysis", class = "btn-primary mb-2"),
  textInput("output_location", "Output Directory (desktop only)",
            placeholder = "C:/Users/me/Documents/outputs or /home/me/outputs"),
  selectizeInput("model_type", "Model Type", choices = NULL,
                 options = list(placeholder = "Select after upload…")),
  selectizeInput("projection_date", "Projection Date", choices = NULL,
                 options = list(placeholder = "Select after upload…")),
  selectizeInput("event_type", "Event / Non-Event",
                 choices = c("Event","Non-Event"), selected = "Non-Event"),
  actionButton("export_excel_now", "Export (Python-style Excel)", class = "btn btn-success"),
  
  # Chart Controls
  h6("Chart Controls:"),
  selectInput("dyn_prod",  "Product", choices = c("ALL"), selected = "ALL"),
  selectInput("dyn_segment_group", "Segment (Group)",
              choices = c("All","NIG","Non NIG"), selected = "All"),
  selectInput("dyn_peril", "Peril",   choices = c("ALL"), selected = "ALL"),
  
  # Exclude-from-Data (from first script)
  h6("Exclude from Data:"),
  div(
    style = "max-height: 180px; overflow:auto; border:1px solid #ddd; padding:6px; border-radius:6px;",
    checkboxGroupInput("exclude_products", label = NULL,
                       choices = character(0), selected = character(0))
  ),
  
  hr(),
  downloadButton("download_zip",   "Download Results (ZIP of CSVs + charts)"),
  downloadButton("download_excel", "Download Results (Excel)")
)

# ---- UI root (HYBRID) ----
ui <- page_sidebar(
  app_header,
  sidebar = sidebar_controls,
  uiOutput("full_header_block"),
  
  # busy overlay element (CSS + JS control)
  # small corner spinner; non-blocking
  tags$div(
    id = "busy-overlay",
    class = "",    # JS toggles 'show'
    tags$div(class = "spinner")
  ),
  
  navset_tab(
    nav_panel("Input Data", uiOutput("preview_card")),
    nav_panel("Results",    uiOutput("results_tabs_ui")),
    nav_panel("Charts",     uiOutput("charts_ui")),
    id = "tabs_main"
  ),
  
  if (ENABLE_ASSISTANT) assistant_button else NULL,
  header = header_css,
  title = "A v E Tracker (Desktop) – Shiny (R) – Actuarial Reporting Team"
)

css_overrides <- tags$style(HTML("
  /* ===== A-E VALUE COLORING (green for negative, red for positive) ===== */
  table.dataTable td.ae-negative {
    background-color: rgba(144, 238, 144, 0.4) !important;
    color: darkgreen !important;
  }
  table.dataTable td.ae-positive {
    background-color: rgba(255, 182, 182, 0.4) !important;
    color: darkred !important;
  }

  /* ===== LINE DIVIDER BETWEEN HEADERS AND DATA ===== */
  /* Remove default DataTables border on scrollHead container to prevent double lines */
  .dataTables_scrollHead {
    border-bottom: none !important;
  }
  div.dataTables_scrollHead {
    border-bottom: none !important;
  }
  /* Bottom border ONLY on the last header row (the bold column names) */
  #tbl_preview thead tr:last-child th {
    border-bottom: 2px solid #333 !important;
  }
  /* Also style the FixedHeader clone */
  .fixedHeader-floating thead tr:last-child th,
  .fixedHeader-locked thead tr:last-child th {
    border-bottom: 2px solid #333 !important;
  }
  /* Remove any top border on body table that could create double line */
  .dataTables_scrollBody,
  .dataTables_scrollBody table.dataTable,
  .dataTables_scrollBody table.dataTable thead,
  .dataTables_scrollBody table.dataTable tbody tr:first-child td {
    border-top: none !important;
  }

  /* ===== CRITICAL: Force ALL cells to shrink to minimum content width ===== */
  /* The 1% width trick forces columns to be as narrow as possible */
  #tbl_preview th,
  #tbl_preview td {
    width: 1% !important;
    white-space: nowrap !important;
    padding: 3px 8px !important;
    box-sizing: border-box !important;
  }

  /* Table must use auto layout and not expand */
  #tbl_preview,
  #tbl_preview.dataTable {
    width: auto !important;
    table-layout: auto !important;
  }

  /* Wrapper should not expand either */
  #tbl_preview_wrapper {
    width: auto !important;
    display: inline-block !important;
    max-width: 100% !important;
    overflow-x: auto !important;
    overflow-y: visible !important;
  }

  /* Sort row and filter row cells also need 1% width */
  #tbl_preview thead tr.dt-sort-row th,
  #tbl_preview thead tr.dt-filter-row th {
    width: 1% !important;
    white-space: nowrap !important;
  }

  /* Filter inputs: shrink to content */
  #tbl_preview thead tr.dt-filter-row input.dt-filter-input {
    width: auto !important;
    min-width: 30px !important;
    max-width: 120px !important;
    box-sizing: border-box !important;
    padding: 2px 4px !important;
    height: 20px !important;
    font-size: 11px !important;
  }

  /* Labels row can wrap if needed, but keep compact */
  #tbl_preview thead tr:not(.dt-sort-row):not(.dt-filter-row) th {
    white-space: nowrap !important;
    width: 1% !important;
  }

  /* FixedHeader clone must match */
  .fixedHeader-floating#tbl_preview th,
  .fixedHeader-floating table#tbl_preview th {
    width: 1% !important;
    white-space: nowrap !important;
  }

  /* ===== FIXED HEADER STYLING ===== */
  /* Ensure FixedHeader has solid background and proper z-index */
  .fixedHeader-floating {
    background-color: #fff !important;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
  }
  .fixedHeader-floating th {
    background-color: #f8f9fa !important;
  }

  /* CRITICAL: Force header and body tables to shrink to content */
  div.dataTables_scrollHeadInner {
    width: auto !important;
    min-width: 0 !important;
  }
  div.dataTables_scrollHeadInner > table.dataTable {
    width: auto !important;
    min-width: 0 !important;
    margin: 0 !important;
  }

  /* Ensure the scroll-head table shrinks to content */
  div.dataTables_scrollHead table.dataTable {
    width: auto !important;
    min-width: 0 !important;
  }

  /* CRITICAL: Remove table-layout:fixed which causes misalignment with scrollX */
  div.dataTables_scrollHead table.dataTable,
  div.dataTables_scrollBody table.dataTable {
    table-layout: auto !important;
  }

  /* Avoid header-cell overflow causing unexpected expansion */
  div.dataTables_scrollHead th,
  div.dataTables_scrollBody th { overflow: hidden !important; }

  /* Force columns to sync between header and body */
  div.dataTables_scrollHead col,
  div.dataTables_scrollBody col {
    width: auto !important;
  }

  /* Box sizing consistency */
  table.dataTable, table.dataTable th, table.dataTable td {
    box-sizing: border-box !important;
  }

  /* ===== CRITICAL: Sort button styling (A/D/- chips) ===== */
  .dt-sortbtn {
    display: inline-block !important;
    padding: 0 6px !important;
    line-height: 18px !important;
    height: 20px !important;
    border: 1px solid #ccc !important;
    border-radius: 3px !important;
    background: #f7f7f7 !important;
    cursor: pointer !important;
    user-select: none !important;
    font-size: 11px !important;
    color: #444 !important;
    margin: 0 1px !important;
  }
  .dt-sortbtn.active {
    background: #d4edda !important;
    border-color: #28a745 !important;
    font-weight: bold !important;
  }
  .dt-sortbox {
    display: inline-flex !important;
    align-items: center !important;
    gap: 4px !important;
  }

  /* ===== Right-align numeric columns (sort buttons + filters on right) ===== */
  thead tr.dt-sort-row th.dt-col-right {
    text-align: right !important;
  }
  thead tr.dt-sort-row th.dt-col-right .dt-sortbox {
    float: right !important;
  }
  thead tr.dt-filter-row th.dt-col-right {
    text-align: right !important;
  }
  thead tr.dt-filter-row th.dt-col-right input.dt-filter-input {
    text-align: right !important;
  }

  /* ===== Dynamic height - pagination directly under data ===== */
  .dataTables_scrollBody {
    height: auto !important;
    max-height: none !important;
    overflow-y: visible !important;
    overflow-x: auto !important;
  }

  /* Solid black Browse button at all times */
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
  #csv_file .btn.disabled, #csv_file .btn:disabled {
    background-color:#000 !important;
    color:#fff !important;
    border-color:#000 !important;
    opacity:.65 !important;
  }
  /* Before upload: thick red border cue */
  #csv_file:not(.used) .btn {
    border: 4px solid #D32F2F !important;
  }
  /* After upload: normal (thin) border */
  #csv_file.used .btn {
    border: 2px solid #000 !important;
  }
  #csv_file_progress .progress-bar { background-color:#000 !important; }
"))

# --- JS helpers (HYBRID) ---
# NOTE: We APPEND to js_code (which already contains js_core + js_dt from 03z_assets_bind.R)
# This preserves the DataTable advanced features (sorting, filtering)
js_code_extra <- "
var __assistKeysInit = false;

// ==== SMART DEFAULTS: localStorage persistence ====
(function() {
  function savePreference(key, value) {
    try {
      if (typeof(Storage) !== 'undefined') {
        localStorage.setItem('ave_pref_' + key, JSON.stringify(value));
      }
    } catch(e) { console.warn('Failed to save preference:', key, e); }
  }

  function loadPreference(key, defaultValue) {
    try {
      if (typeof(Storage) !== 'undefined') {
        var stored = localStorage.getItem('ave_pref_' + key);
        if (stored !== null) return JSON.parse(stored);
      }
    } catch(e) { console.warn('Failed to load preference:', key, e); }
    return defaultValue;
  }

  document.addEventListener('shiny:inputchanged', function(event) {
    if (!event || !event.detail) return;
    var name = event.detail.name;
    var value = event.detail.value;
    if (name === 'event_type') savePreference('event_type', value);
    else if (name === 'dyn_segment_group') savePreference('segment_group', value);
  }, {passive:true});

  document.addEventListener('shiny:connected', function() {
    setTimeout(function() {
      var eventType = loadPreference('event_type', null);
      if (eventType && document.getElementById('event_type')) {
        var sel = document.getElementById('event_type');
        if (sel) sel.value = eventType;
        Shiny.setInputValue('event_type', eventType);
      }
      var segGroup = loadPreference('segment_group', null);
      if (segGroup && document.getElementById('dyn_segment_group')) {
        var sel = document.getElementById('dyn_segment_group');
        if (sel) sel.value = segGroup;
        Shiny.setInputValue('dyn_segment_group', segGroup);
      }
      console.log('[Smart Defaults] Preferences restored');
    }, 500);
  }, {passive:true});
})();
// ==== END SMART DEFAULTS ====

// ==== KEYBOARD SHORTCUTS ====
document.addEventListener('keydown', function(e) {
  // Skip if user is typing in an input field
  var target = e.target;
  if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT')) {
    return;
  }

  var isMac = navigator.platform && navigator.platform.toUpperCase().indexOf('MAC') >= 0;
  var cmdCtrl = isMac ? e.metaKey : e.ctrlKey;

  // Ctrl/Cmd + Enter: Run Analysis
  if (cmdCtrl && e.key === 'Enter') {
    e.preventDefault();
    var btn = document.getElementById('run_analysis');
    if (btn) {
      btn.click();
      console.log('[Shortcut] Run Analysis triggered');
    }
  }
  // Ctrl/Cmd + D: Download Excel
  else if (cmdCtrl && (e.key === 'd' || e.key === 'D')) {
    e.preventDefault();
    var btn = document.getElementById('download_excel');
    if (btn) {
      btn.click();
      console.log('[Shortcut] Download Excel triggered');
    }
  }
  // Ctrl/Cmd + Shift + Z: Download ZIP
  else if (cmdCtrl && e.shiftKey && (e.key === 'z' || e.key === 'Z')) {
    e.preventDefault();
    var btn = document.getElementById('download_zip');
    if (btn) {
      btn.click();
      console.log('[Shortcut] Download ZIP triggered');
    }
  }
  // ? key: Show keyboard shortcuts help
  else if (e.key === '?' && !e.shiftKey) {
    e.preventDefault();
    var msg = 'KEYBOARD SHORTCUTS:\\n' +
              '─────────────────\\n' +
              'Ctrl+Enter:     Run Analysis\\n' +
              'Ctrl+D:         Download Excel\\n' +
              'Ctrl+Shift+Z:   Download ZIP\\n' +
              'Ctrl/Cmd+K:     Open Assistant\\n' +
              '?:              Show this help';
    alert(msg);
  }
}, {passive:false});
// ==== END KEYBOARD SHORTCUTS ====

Shiny.addCustomMessageHandler('toggleOverlay', function(x){
  var el = document.getElementById('busy-overlay'); if(!el) return;
  if (x && x.show) el.classList.add('show'); else el.classList.remove('show');
});
// Robust expand/collapse for .plot-wrap (resizes all Plotly charts inside)
document.addEventListener('click', function(e){
  var a = e.target.closest('.expand-btn');
  if (!a) return;
  e.preventDefault();

  var id = a.getAttribute('data-target');
  var el = document.getElementById(id);
  if (!el) return;

  var goingFS = !el.classList.contains('is-fullscreen');
  el.classList.toggle('is-fullscreen', goingFS);

  // lock/unlock page scroll
  try { document.body.style.overflow = goingFS ? 'hidden' : ''; } catch(_) {}

  // schedule a few resizes to catch CSS transitions & fonts
  function doResize() {
    try {
      var nodes = el.querySelectorAll('.js-plotly-plot, .plotly');
      if (nodes.length && window.Plotly && Plotly.Plots && Plotly.Plots.resize) {
        nodes.forEach(function(p){
          try {
            Plotly.Plots.resize(p);
            Plotly.relayout(p, {autosize: true});
          } catch(_) {}
        });
      }
    } catch(_) {}
  }
  window.dispatchEvent(new Event('resize'));
  setTimeout(doResize, 50);
  setTimeout(doResize, 180);
  setTimeout(doResize, 400);
}, {passive:false});
document.addEventListener('keydown', function(e){
  if ((e.key || '').toLowerCase() === 'escape') {
    var fs = document.querySelector('.plot-wrap.is-fullscreen');
    if (fs) fs.classList.remove('is-fullscreen');
  }
}, {passive:true});
Shiny.addCustomMessageHandler('triggerDownload', function(x){
  var id = x.id;
  var el = document.querySelector('[data-download-id='+id+']') || document.querySelector('[data-shiny-input-id='+id+']');
  if (el) el.click();
});
Shiny.addCustomMessageHandler('injectKeys', function(_) {
  if (__assistKeysInit) return; __assistKeysInit = true;
  function openModal(){
    var btn = document.querySelector('#assist_open'); if(btn){ btn.click(); }
    setTimeout(function(){
      var inp = document.querySelector('input#assist_search'); if(inp){ inp.focus(); }
    }, 50);
  }
  document.addEventListener('keydown', function(e){
    var isMac = navigator.platform && navigator.platform.toUpperCase().indexOf('MAC') >= 0;
    var key = (e.key || '').toLowerCase();
    var cmdK = (isMac && e.metaKey && key === 'k') || (!isMac && e.ctrlKey && key === 'k');
    if (cmdK || key === '/') { e.preventDefault(); openModal(); }
  }, {passive:false});
});
// ---- Robust \"Browse used\" toggle for #csv_file ----
(function(){
  function getFileInput(){ 
    var wrap = document.getElementById('csv_file'); 
    if (!wrap) return null;
    return wrap.querySelector('input[type=file]');
  }
  function setUsedClass(){
    var wrap = document.getElementById('csv_file');
    var inp  = getFileInput();
    if (!wrap || !inp) return;
    var hasFile = !!(inp.files && inp.files.length > 0);
    wrap.classList.toggle('used', hasFile);
  }

  document.addEventListener('change', function(e){
    var inp = e.target.closest('#csv_file input[type=file]');
    if (!inp) return;
    setTimeout(setUsedClass, 0);
  }, {passive:true});

  document.addEventListener('shiny:inputchanged', function(e){
    if (!e || !e.detail) return;
    if (e.detail.name === 'csv_file') setTimeout(setUsedClass, 0);
  }, {passive:true});

  document.addEventListener('DOMContentLoaded', function(){
    setTimeout(setUsedClass, 0);
    setTimeout(setUsedClass, 200);
    setTimeout(setUsedClass, 800);
  }, {passive:true});
  document.addEventListener('shiny:connected', function(){
    setTimeout(setUsedClass, 0);
  }, {passive:true});

  var moStarted = false;
  function startObserver(){
    if (moStarted) return; moStarted = true;
    var wrap = document.getElementById('csv_file');
    if (!wrap || !window.MutationObserver) return;
    var mo = new MutationObserver(function(){ setUsedClass(); });
    mo.observe(wrap, { childList:true, subtree:true });
  }
  startObserver();
  setTimeout(startObserver, 500);
})();
"

# Combine: js_code from 03z_assets_bind.R (contains DataTable features) + js_code_extra (UI helpers)
if (exists("js_code", inherits = TRUE)) {
  js_code <- paste(js_code, js_code_extra, sep = "\n")
} else {
  js_code <- js_code_extra
}

# IMPORTANT: Inject the combined JavaScript into the UI
# The ui object was defined above without js_code, so we need to add it here
ui <- htmltools::tagList(
  ui,
  css_overrides,
  tags$script(htmltools::HTML(js_code))
)
