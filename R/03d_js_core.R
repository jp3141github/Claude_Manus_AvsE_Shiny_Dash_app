# R/03d_js_core.R — Generic JS (fullscreen, reset, overlay, uploader, wait killer, hotkeys)

js_core <- "
var __assistKeysInit = false;

Shiny.addCustomMessageHandler('toggleOverlay', function(x){
  var el = document.getElementById('busy-overlay'); if(!el) return;
  if (x && x.show) el.classList.add('show'); else el.classList.remove('show');
});

/* ===== BULLETPROOF FULLSCREEN (reparent to overlay) ===== */
(function(){
  var FS = {
    host: null, wrap: null, dimmer: null, closeBtn: null,
    active: null,          // the .plot-wrap currently fullscreen
    placeholder: null,     // comment node marking original position
    origStyle: ''          // inline style to restore
  };

  function ensureHost(){
    if (FS.host) return true;
    try{
      var h = document.createElement('div'); h.id = 'fs-host';
      var dim = document.createElement('div'); dim.className = 'fs-dimmer';
      var box = document.createElement('div'); box.className = 'fs-wrap';
      var btn = document.createElement('div'); btn.className = 'fs-close'; btn.textContent = '× Close';
      h.appendChild(dim); h.appendChild(box); h.appendChild(btn);
      document.body.appendChild(h);
      FS.host = h; FS.wrap = box; FS.dimmer = dim; FS.closeBtn = btn;

      dim.addEventListener('click', exitFS, {passive:true});
      btn.addEventListener('click', exitFS, {passive:true});
      window.addEventListener('resize', function(){ if (FS.active) scheduleResize(FS.active); }, {passive:true});
      return true;
    }catch(e){ return false; }
  }

  function scheduleResize(root){
    try{
      var nodes = root.querySelectorAll('.js-plotly-plot');
      if (!nodes || !nodes.length) return;
      function nudge(gd){
        try{
          if (gd && gd.layout){
            gd.layout.autosize = true;
            if ('width' in gd.layout) gd.layout.width = null;
            if ('height' in gd.layout) gd.layout.height = null;
          }
          if (window.Plotly && window.Plotly.Plots && window.Plotly.Plots.resize){
            window.Plotly.Plots.resize(gd);
            window.Plotly.relayout(gd, {autosize:true});
          }
        }catch(_){}
      }
      [40,120,320,640,960].forEach(function(t){ setTimeout(function(){ nodes.forEach(nudge); }, t); });
    }catch(_){}
  }

  function enterFS(plotWrap){
    if (!ensureHost()) return fallbackClassToggle(plotWrap);
    if (FS.active) exitFS();

    var ph = document.createComment('fs-ph');
    plotWrap.parentNode.insertBefore(ph, plotWrap);

    FS.origStyle = plotWrap.getAttribute('style') || '';
    plotWrap.setAttribute('data-fs-orig-style', FS.origStyle);
    plotWrap.style.height = '100%';
    plotWrap.style.width  = '100%';

    FS.wrap.appendChild(plotWrap);
    FS.placeholder = ph;
    FS.active      = plotWrap;

    FS.host.classList.add('show');
    try { window.scrollTo({top: 0, behavior: 'instant'}); } catch(_) { window.scrollTo(0,0); }
    try { document.body.classList.add('body--no-scroll'); } catch(_){}

    scheduleResize(plotWrap);
  }

  function exitFS(){
    if (!FS.active) return;
    try{
      var wrap = FS.active, ph = FS.placeholder;
      if (ph && ph.parentNode) ph.parentNode.insertBefore(wrap, ph);
      if (ph && ph.parentNode) ph.parentNode.removeChild(ph);
      var s = wrap.getAttribute('data-fs-orig-style') || FS.origStyle || '';
      if (s) wrap.setAttribute('style', s); else wrap.removeAttribute('style');

      FS.host.classList.remove('show');
      try { document.body.classList.remove('body--no-scroll'); } catch(_){}

      scheduleResize(wrap);
    }catch(_){}
    FS.active = null; FS.placeholder = null; FS.origStyle = '';
  }

  function fallbackClassToggle(plotWrap){
    var goingFS = !plotWrap.classList.contains('is-fullscreen');
    plotWrap.classList.toggle('is-fullscreen', goingFS);
    try { document.body.classList.toggle('body--no-scroll', goingFS); } catch(_){}
    scheduleResize(plotWrap);
  }

  document.addEventListener('click', function(e){
    var btn = e.target.closest('.expand-btn'); if (!btn) return; e.preventDefault();
    var wrap = null, id = btn.getAttribute('data-target'); if (id) wrap = document.getElementById(id);
    if (!wrap) { var card = btn.closest('.bslib-card, .card'); if (card) wrap = card.querySelector('.plot-wrap'); }
    if (!wrap) return;

    if (FS.active === wrap) { exitFS(); return; }
    enterFS(wrap);
  }, {passive:false});

  document.addEventListener('keydown', function(e){
    if ((e.key||'').toLowerCase() === 'escape'){
      if (FS.active) { exitFS(); return; }
      var fs = document.querySelector('.plot-wrap.is-fullscreen');
      if (fs) {
        fs.classList.remove('is-fullscreen');
        try { document.body.classList.remove('body--no-scroll'); } catch(_){}
      }
    }
  }, {passive:true});

})();

/* Reset (full state: tools, axes, legend, spikes, selections) */
document.addEventListener('click', function(e){
  var btn = e.target.closest('.reset-btn'); if (!btn) return; e.preventDefault();

  var wrap = null, id = btn.getAttribute('data-target'); if (id) wrap = document.getElementById(id);
  if (!wrap) { var card = btn.closest('.bslib-card, .card'); if (card) wrap = card.querySelector('.plot-wrap'); }
  if (!wrap) return;
  var gd = wrap.querySelector('.js-plotly-plot'); if (!gd || !window.Plotly) return;

  try {
    var traceIdx = [];
    for (var i = 0; i < (gd.data || []).length; i++) traceIdx.push(i);
    if (traceIdx.length) Plotly.restyle(gd, { selectedpoints: null }, traceIdx);

    var layout = gd.layout || {}, relayout = {};

    Object.keys(layout).forEach(function(k){
      if (/^xaxis([0-9]+)?$/.test(k) || /^yaxis([0-9]+)?$/.test(k)) {
        relayout[k + '.autorange']  = true;
        relayout[k + '.showspikes'] = true;
        relayout[k + '.spikemode']  = 'across';
        relayout[k + '.spikesnap']  = 'cursor';
      }
    });

    if (!Object.keys(relayout).length) {
      relayout = {
        'xaxis.autorange': true, 'yaxis.autorange': true,
        'xaxis.showspikes': true, 'yaxis.showspikes': true,
        'xaxis.spikemode': 'across', 'yaxis.spikemode': 'across',
        'xaxis.spikesnap': 'cursor', 'yaxis.spikesnap': 'cursor'
      };
    }

    relayout['hovermode'] = 'closest';
    relayout['legend.visible'] = true;

    Plotly.relayout(gd, relayout).then(function(){
      Plotly.relayout(gd, { dragmode: 'zoom' });
      if (gd.layout) { gd.layout.autosize = true; gd.layout.width = null; gd.layout.height = null; }
      Plotly.Plots.resize(gd);
    });

  } catch(_) {}
}, {passive:false});

/* ESC to exit fullscreen */
document.addEventListener('keydown', function(e){
  if ((e.key||'').toLowerCase()==='escape'){
    var fs=document.querySelector('.plot-wrap.is-fullscreen'); if(fs) fs.classList.remove('is-fullscreen');
    try { document.body.classList.remove('body--no-scroll'); } catch(_) {}
  }
},{passive:true});

/* Export current Plotly figure (PNG default, hold Alt for SVG) */
document.addEventListener('click', function(e){
  var btn = e.target.closest('.export-btn'); if (!btn) return;
  e.preventDefault();

  // Locate the target plot wrapper and the Plotly graph div
  var wrap = null, id = btn.getAttribute('data-target');
  if (id) wrap = document.getElementById(id);
  if (!wrap) {
    var card = btn.closest('.bslib-card, .card');
    if (card) wrap = card.querySelector('.plot-wrap');
  }
  if (!wrap) return;

  var gd = wrap.querySelector('.js-plotly-plot');
  if (!gd || !window.Plotly || !Plotly.downloadImage) {
    console.warn('Export: no Plotly graph found in target.');
    return;
  }

  // Helpers for filename
  function clean(s){
    if (!s) return '';
    return String(s).replace(/\\s+/g,' ').trim();
  }
  function safeName(s){
    s = (s || 'plotly_chart').replace(/[\\\\/:*?\\\"<>|]+/g, '_').slice(0, 80);
    return s || 'plotly_chart';
  }
  function timestamp(){
    var d = new Date(), p = function(n){ return (n<10?'0':'') + n; };
    return d.getFullYear()+''+p(d.getMonth()+1)+p(d.getDate())+'_'+p(d.getHours())+p(d.getMinutes())+p(d.getSeconds());
  }

  var titleAttr = clean(btn.getAttribute('data-title'));
  var card = btn.closest('.bslib-card, .card');
  var headerText = '';
  if (card){
    var hdr = card.querySelector('.card-header, .bslib-card .card-header, .bslib-card .card-title');
    if (hdr) headerText = clean(hdr.textContent || '');
  }
  var base = safeName(titleAttr || headerText || gd.getAttribute('id') || 'plotly_chart');
  var fname = base + '_' + timestamp();

  // Alt-click exports SVG, normal click PNG
  var fmt = (e.altKey ? 'svg' : 'png');

  // Keep PNG crisp via 2x scale; SVG ignores scale
  var opts = {
    format: fmt,
    filename: fname,
    scale: (fmt === 'png' ? 2 : 1)
  };

  try {
    Plotly.downloadImage(gd, opts);
  } catch(err) {
    console.error('Export failed:', err);
  }
}, {passive:false});

/* Trigger click helpers */
Shiny.addCustomMessageHandler('triggerDownload', function(x){
  var el = document.querySelector('[data-download-id='+x.id+']') || document.querySelector('[data-shiny-input-id='+x.id+']'); if (el) el.click();
});

/* Assistant hotkeys */
Shiny.addCustomMessageHandler('injectKeys', function(_) {
  if (__assistKeysInit) return; __assistKeysInit = true;
  function openModal(){
    var btn=document.querySelector('#assist_open'); if(btn){ btn.click(); }
    setTimeout(function(){ var inp=document.querySelector('input#assist_search'); if(inp){ inp.focus(); } }, 50);
  }
  document.addEventListener('keydown', function(e){
    var isMac = navigator.platform && navigator.platform.toUpperCase().indexOf('MAC')>=0;
    var key=(e.key||'').toLowerCase(); var cmdK=(isMac && e.metaKey && key==='k') || (!isMac && e.ctrlKey && key==='k');
    if (cmdK || key === '/') { e.preventDefault(); openModal(); }
  }, {passive:false});
});

/* Uploader: red border until a file is chosen */
(function(){
  function getFileInput(){ var wrap=document.getElementById('csv_file'); if(!wrap) return null; return wrap.querySelector('input[type=file]'); }
  function setUsedClass(){ var wrap=document.getElementById('csv_file'); var inp=getFileInput(); if(!wrap || !inp) return; var hasFile=!!(inp.files && inp.files.length>0); wrap.classList.toggle('used', hasFile); }
  document.addEventListener('change', function(e){ var inp=e.target.closest('#csv_file input[type=file]'); if(!inp) return; setTimeout(setUsedClass, 0); }, {passive:true});
  document.addEventListener('shiny:inputchanged', function(e){ if (!e||!e.detail) return; if (e.detail.name==='csv_file') setTimeout(setUsedClass, 0); }, {passive:true});
  document.addEventListener('DOMContentLoaded', function(){ [0,200,800].forEach(function(t){ setTimeout(setUsedClass, t); }); }, {passive:true});
  document.addEventListener('shiny:connected', function(){ setUsedClass(); }, {passive:true});
  var moStarted=false; function startObserver(){ if(moStarted) return; moStarted=true; var wrap=document.getElementById('csv_file'); if(!wrap||!window.MutationObserver) return;
    var mo=new MutationObserver(function(){ setUsedClass(); }); mo.observe(wrap,{childList:true,subtree:true});
  }
  startObserver(); setTimeout(startObserver, 500);
})();

/* Charts wait killer */
(function(){
  function removeChartsWait(){
    var wrap = document.getElementById('charts_wait_wrap'); if (!wrap) return;
    try { wrap.remove(); } catch(_) { if (wrap.parentNode) wrap.parentNode.removeChild(wrap); }
  }
  function chartsPresent(root){ try { return !!(root && root.querySelector('.js-plotly-plot, .plotly')); } catch(_) { return false; } }
  var host = document.getElementById('charts_container');
  if (host && chartsPresent(host)) { removeChartsWait(); }
  if (host && window.MutationObserver){
    var mo = new MutationObserver(function(){ if (chartsPresent(host)) { removeChartsWait(); mo.disconnect(); } });
    mo.observe(host, {childList:true, subtree:true});
  }
  document.addEventListener('shiny:value', function(e){
    if (e && e.detail && typeof e.detail.name === 'string' && e.detail.name.indexOf('dyn_') === 0){ removeChartsWait(); }
  }, {passive:true});
  document.addEventListener('DOMContentLoaded', function(){ [600,1200].forEach(function(t){ setTimeout(removeChartsWait, t); }); }, {passive:true});
})();

/* Download current view (CSV) — exactly what is on screen (page, filters, order, visible columns) */
(function(){
  function cleanText(s){
    if (s == null) return \"\";
    return String(s).replace(/\\r?\\n|\\r/g, \" \").replace(/\\s+/g,\" \").trim();
  }
  function activePane(){
    var p = document.querySelector(\"#tabs_main .tab-pane.active\");
    return p || document;
  }
  function getWrapper(pane){
    // pick the first visible DataTables wrapper in the active pane
    var els = pane.querySelectorAll(\".dataTables_wrapper\");
    for (var i=0;i<els.length;i++){
      if (els[i].offsetParent !== null) return els[i];
    }
    return null;
  }
  function headerCells(wrapper){
    // use scrollHead table if present; otherwise fallback to main table header
    var headTable = wrapper.querySelector(\"div.dataTables_scrollHead table\") || wrapper.querySelector(\"table.dataTable\");
    if (!headTable) return [];
    var thead = headTable.querySelector(\"thead\"); if (!thead) return [];
    // labels row only (skip our chips/filters rows)
    var rows = thead.querySelectorAll(\"tr:not(.dt-sort-row):not(.dt-filter-row)\");
    var row = rows[rows.length - 1];
    if (!row) return [];
    return Array.from(row.querySelectorAll(\"th\"));
  }
  function bodyRows(wrapper){
    var bodyTable = wrapper.querySelector(\"div.dataTables_scrollBody table\") || wrapper.querySelector(\"table.dataTable\");
    if (!bodyTable) return [];
    // Only current page rows are in DOM under paging; filter out hidden rows
    return Array.from(bodyTable.querySelectorAll(\"tbody tr\")).filter(function(tr){
      return tr.offsetParent !== null && tr.querySelectorAll(\"td\").length > 0;
    });
  }
  function cellText(el){
    if (!el) return \"\";
    var t = el.innerText || el.textContent || \"\";
    return cleanText(t);
  }
  function toCSV(rows){
    function esc(s){
      s = s.replace(/\\\"/g, '\"\"');
      return /[\\\",\\r\\n]/.test(s) ? '\"' + s + '\"' : s;
    }
    return rows.map(function(r){ return r.map(esc).join(\",\"); }).join(\"\\r\\n\");
  }
  function timestamp(){
    var d = new Date();
    function p(n){ return (n<10 ? \"0\":\"\") + n; }
    return d.getFullYear().toString() + p(d.getMonth()+1) + p(d.getDate()) + \"_\" + p(d.getHours()) + p(d.getMinutes()) + p(d.getSeconds());
  }
  function activeContextName(){
    var main = document.querySelector(\"#tabs_main .nav-link.active\");
    var mainName = main ? cleanText(main.textContent) : \"View\";
    if (mainName === \"Results\"){
      var inner = document.querySelector(\"#tabs_results_inner .nav-link.active\");
      if (inner) return \"Results_\" + cleanText(inner.textContent).replace(/\\s+/g,\"-\").slice(0,60);
    }
    return mainName.replace(/\\s+/g,\"-\");
  }

  document.addEventListener(\"click\", function(e){
    var btn = e.target.closest(\"#download_view_csv\");
    if (!btn) return;
    e.preventDefault();

    var pane = activePane();
    var wrapper = getWrapper(pane);
    if (!wrapper){ console.warn(\"No visible DataTable to export.\"); return; }

    var headers = headerCells(wrapper).map(function(th){ return cellText(th); });
    if (!headers.length){ console.warn(\"No headers found to export.\"); return; }

    var rows = bodyRows(wrapper).map(function(tr){
      return Array.from(tr.querySelectorAll(\"td\")).map(cellText);
    });

    var csv = \"\\ufeff\" + toCSV([headers].concat(rows)); // UTF-8 BOM for Excel-friendliness
    var name = \"view_\" + activeContextName() + \"_\" + timestamp() + \".csv\";

    try{
      var blob = new Blob([csv], {type: \"text/csv;charset=utf-8;\"});
      var url = URL.createObjectURL(blob);
      var a = document.createElement(\"a\");
      a.href = url; a.download = name;
      document.body.appendChild(a);
      a.click();
      setTimeout(function(){ URL.revokeObjectURL(url); document.body.removeChild(a); }, 0);
    }catch(err){
      console.error(\"CSV download failed\", err);
    }
  }, {passive:false});
})();
"
