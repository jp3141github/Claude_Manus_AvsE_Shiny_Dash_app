# R/03e_js_dt_adv.R — DataTables advanced header (chips + filters, FixedHeader-safe, Clear-Sort + Page Jumper)
# Adds Apply/Clear filters to ALL tables and persists filter values across rebuilds.

js_dt <- '
console.log("[JS] DataTables Advanced Header JS loaded");

/* =======================================================================
   DataTables Advanced Header Utilities
   - Per-table A/D/− chips above headers (multi-order with position badges)
   - Per-column filter inputs above headers (apply on Enter)
   - Clear-all-sorting control
   - Page jumper near the paginator
   - Preserves column filter input values across redraws/rebuilds
   - Apply filters + Clear filters buttons on ALL tables
   - Fully compatible with scrollX + FixedHeader (original, scroll-head, and
     FixedHeader clones are rebuilt & kept in sync)
   ======================================================================= */

/* -------- Page jumper (adds "Jump to <n>" next to paginator) ------------ */
window.dtAddPageJumper = function(){
  return function(settings){
    try{
      var api   = new $.fn.dataTable.Api(settings);
      var node  = api.table().node();
      if (!node) return;
      var id    = node.id || ("dt_" + Math.random().toString(36).slice(2));
      var $cont = $(api.table().container());
      var ns    = ".dtjump."+id;

      function inject(){
        var $p = $cont.find("div.dataTables_paginate");
        if (!$p.length) return;
        if ($p.find(".dt-jumpwrap").length) return;

        var html = [
          \'<span class="dt-jumpwrap" style="margin-left:8px;font-size:12px;vertical-align:middle;">\',
          \'Jump to \',
          \'<input type="number" class="dt-jump" min="1" style="width:72px;height:24px;padding:2px 4px;display:inline-block;">\',
          \'</span>\'
        ].join("");
        $p.append(html);

        $p.off("keydown"+ns, ".dt-jump").on("keydown"+ns, ".dt-jump", function(e){
          if (e.key === "Enter"){
            var v = parseInt(this.value, 10);
            if (!isFinite(v) || v < 1) return;
            var info = api.page.info();
            var page = Math.max(0, Math.min(v-1, Math.max(0, info.pages-1)));
            api.page(page).draw("page");
          }
        });
      }

      api.off("draw.dt"+ns).on("draw.dt"+ns, inject);
      inject();
    }catch(e){ console.error("dtAddPageJumper error:", e); }
  };
};

/* -------- Advanced header (chips + filters + clear-sort + filter persistence) -------- */
window.dtAdvInit = function() {
  return function(settings) {
    try {
      var api   = new $.fn.dataTable.Api(settings);
      var $tbl  = $(api.table().node());
      var $cont = $(api.table().container());

      var id = $tbl.attr("id");
      if (!id) { id = "dt_" + Math.random().toString(36).slice(2); $tbl.attr("id", id); }
      // Filter controls now enabled on ALL tables (not just preview)

      var sortStack = [];
      var KEY_FILTERS = "dtColFilters:" + id;   // per-table store of RAW input values (not regex)

      function locateHeads(){
        var $theadVis = $cont.find("div.dataTables_scrollHead thead");
        if (!$theadVis.length) $theadVis = $tbl.children("thead");
        var $theads = $theadVis;
        var $theadOrig = $tbl.children("thead");
        if ($theadOrig.length && !$theads.is($theadOrig)) $theads = $theads.add($theadOrig);
        var $fh = $(".fixedHeader-floating table#"+id+" thead, .fixedHeader-locked table#"+id+" thead");
        if ($fh.length) $theads = $theads.add($fh);
        return { $theadVis: $theadVis, $theads: $theads };
      }

      function buildRows(n){
        var $srow = $("<tr class=\\"dt-sort-row\\"></tr>");
        var $frow = $("<tr class=\\"dt-filter-row\\"></tr>");
        for (var i=0;i<n;i++){
          var $thS = $("<th></th>");
          var $box = $("<span class=\\"dt-sortbox\\"></span>");
          function mk(txt, dir){
            var $b = $("<span class=\\"dt-sortbtn\\"></span>").text(txt).attr("data-dir",dir);
            $b.append("<span class=\\"dt-badge\\"></span>");
            return $b;
          }
          $box.append(mk("A","asc"), mk("D","desc"), mk("−","none"));
          $thS.append($box); $srow.append($thS);

          var $thF = $("<th></th>");
          var $inp = $("<input type=\\"text\\" class=\\"dt-filter-input\\" placeholder=\\"filter\\" data-col=\\""+i+"\\">");
          $thF.append($inp); $frow.append($thF);
        }
        return {$srow:$srow, $frow:$frow};
      }

      // ---- Simple text search (no regex to avoid issues with numeric columns) ----
      // For OR support: "NIG;DLI" is handled by searching for each term
      function buildSearchTerm(raw){
        if (!raw) return "";
        return raw.trim();
      }

      // Persist RAW input values (not regex) in container data
      function saveRawFiltersFromHead($thead){
        try{
          var vals = [];
          $thead.find("tr.dt-filter-row th input.dt-filter-input").each(function(i){ vals[i] = this.value || ""; });
          $cont.data(KEY_FILTERS, vals);
        }catch(e){}
      }
      function getSavedRawFilters(){
        var vals = $cont.data(KEY_FILTERS);
        return Array.isArray(vals) ? vals : null;
      }

      // Fallback: read current inputs from visible thead (pre-rebuild)
      function readInputsFromVisibleHead(heads){
        try{
          var vals = [];
          var $cells = heads.$theadVis.find("tr.dt-filter-row th input.dt-filter-input");
          if (!$cells.length) return null;
          $cells.each(function(i){ vals[i] = this.value || ""; });
          return vals;
        }catch(e){ return null; }
      }

      // Fallback: read API search strings (regex strings), used only if we have nothing else
      function readFilterValsFromApi(){
        var vals = [];
        api.columns(":visible").every(function(vidx){
          var s = this.search();
          vals.push(s || "");
        });
        return vals;
      }

      // Write RAW input values into every thead clone
      function writeRawFilterInputs(heads, rawVals){
        if (!rawVals) return;
        try{
          heads.$theads.each(function(){
            var $h = $(this);
            var $cells = $h.find("tr.dt-filter-row th input.dt-filter-input");
            if (!$cells.length) return;
            $cells.each(function(i){
              var v = (i < rawVals.length) ? rawVals[i] : "";
              if (this.value !== v) this.value = v;
            });
          });
        }catch(e){}
      }

      // Placeholder - width locking removed to prevent regressions
      function lockTableLayout(heads){
        // Do nothing - let DataTables handle column widths naturally
        return;
      }

      function syncFilterWidths(heads){
        try{
          // Measure header text width and set filter input slightly wider
          var $labelRow = heads.$theadVis.find("tr:not(.dt-sort-row):not(.dt-filter-row):last th");
          var $filterRow = heads.$theadVis.find("tr.dt-filter-row th");

          $labelRow.each(function(i){
            var headerText = $(this).text().trim();
            // Create temp span to measure text width
            var $temp = $("<span>").text(headerText).css({
              "font-size": $(this).css("font-size"),
              "font-family": $(this).css("font-family"),
              "font-weight": $(this).css("font-weight"),
              "position": "absolute",
              "visibility": "hidden",
              "white-space": "nowrap"
            }).appendTo("body");
            var textWidth = $temp.width();
            $temp.remove();

            // Set filter input width: header text width + 20px padding (min 40px)
            var inputWidth = Math.max(40, textWidth + 20);
            var $filterCell = $filterRow.eq(i);
            var $input = $filterCell.find("input.dt-filter-input");
            if ($input.length) {
              $input.css("width", inputWidth + "px");
            }
          });
        } catch(e){ console.warn("syncFilterWidths error:", e); }
      }

      function renderBadges(heads){
        try{
          var $scope = heads.$theads;
          $scope.find(".dt-sortbtn").removeClass("has-badge active").each(function(){ $(this).find(".dt-badge").text(""); });
          sortStack.forEach(function(entry, idx){
            var visIdx = api.column(entry.colIdx).visible() ? api.column(entry.colIdx).index("toVisible") : null;
            if (visIdx == null) return;
            var $cell = $scope.find("tr.dt-sort-row th").eq(visIdx);
            var sel   = entry.dir === "asc" ? ".dt-sortbtn[data-dir=asc]" : ".dt-sortbtn[data-dir=desc]";
            var $btn  = $cell.find(sel);
            $btn.addClass("active has-badge").find(".dt-badge").text(idx+1);
          });
        } catch(e){}
      }

      // Detect column alignment based on column name and data content (numeric = right-aligned)
      function detectColumnAlignments(heads){
        try{
          // Get column names from header labels
          var $labelRow = heads.$theadVis.find("tr:not(.dt-sort-row):not(.dt-filter-row):last th");
          var alignments = [];

          // Check first few rows of data to detect if column is numeric
          var $bodyTable = $cont.find("div.dataTables_scrollBody table.dataTable");
          if (!$bodyTable.length) $bodyTable = $tbl;
          var $rows = $bodyTable.find("tbody tr").slice(0, 10);

          $labelRow.each(function(i){
            var colName = $(this).text().trim().toLowerCase();
            var isRightAligned = false;

            // Known text columns that should be left-aligned
            var leftAlignCols = ["projectiondate", "projection date", "objectname", "object name",
                                "section", "product", "peril", "measure", "segment", "model type",
                                "event / non-event", "event/non-event", "current or prior"];

            // Known numeric columns that should be right-aligned
            var rightAlignCols = ["actual", "expected", "accident period", "accidentperiod",
                                 "accident year", "accidentyear", "amount", "value", "count", "total"];

            // Check if column name suggests left-alignment
            var isTextCol = leftAlignCols.some(function(lc){ return colName.indexOf(lc) >= 0; });

            // Check if column name suggests right-alignment (numeric)
            var isNumericCol = rightAlignCols.some(function(rc){ return colName.indexOf(rc) >= 0; });

            // Also check if column name is a year (e.g., 2010, 2011, 2012, etc.)
            var isYearCol = /^[0-9]{4}$/.test(colName.trim());

            console.log("[DT Alignment] Col", i, "name:", colName, "isTextCol:", isTextCol, "isNumericCol:", isNumericCol, "isYearCol:", isYearCol);

            if (isTextCol) {
              isRightAligned = false;
            } else if (isNumericCol || isYearCol) {
              isRightAligned = true;
            } else {
              // Check actual data - if most values look numeric, right-align
              var numericCount = 0;
              var totalChecked = 0;
              $rows.each(function(){
                var $cell = $(this).find("td").eq(i);
                if ($cell.length) {
                  var val = $cell.text().trim();
                  totalChecked++;
                  // Check if value looks numeric (including currency, commas, brackets, decimals)
                  if (/^[()\\-\\d,.$£€\\s]+$/.test(val) && val.length > 0 && /\\d/.test(val)) {
                    numericCount++;
                  }
                }
              });
              isRightAligned = totalChecked > 0 && (numericCount / totalChecked) > 0.5;
            }

            alignments[i] = isRightAligned ? "right" : "left";
          });

          return alignments;
        }catch(e){ console.warn("detectColumnAlignments error:", e); return []; }
      }

      // Apply alignment to sort and filter rows (class-based for CSS flexbox)
      function applyColumnAlignments(heads, alignments){
        try{
          console.log("[DT Alignment] applyColumnAlignments called, theads count:", heads.$theads.length, "alignments:", alignments.length);

          if (!alignments || alignments.length === 0) {
            console.warn("[DT Alignment] No alignments to apply");
            return;
          }

          heads.$theads.each(function(theadIdx){
            var $h = $(this);
            var $sortCells = $h.find("tr.dt-sort-row th");
            var $filterCells = $h.find("tr.dt-filter-row th");
            console.log("[DT Alignment] Thead", theadIdx, "- sortCells:", $sortCells.length, "filterCells:", $filterCells.length);

            if ($sortCells.length === 0) {
              console.warn("[DT Alignment] No sort cells found in thead", theadIdx);
              return;
            }

            alignments.forEach(function(align, i){
              if (align === "right") {
                var $sortCell = $sortCells.eq(i);
                var $filterCell = $filterCells.eq(i);

                if ($sortCell.length === 0) {
                  console.warn("[DT Alignment] No sortCell at index", i);
                  return;
                }

                // Add the class - CSS uses text-align:right + float:right for sortbox
                // DO NOT use display:flex as it breaks table-cell layout
                $sortCell.addClass("dt-col-right").css("text-align", "right");
                $filterCell.addClass("dt-col-right").css("text-align", "right");

                // Float the sortbox to the right
                $sortCell.find(".dt-sortbox").css("float", "right");

                // Also right-align the filter input text
                $filterCell.find("input.dt-filter-input").css("text-align", "right");

                console.log("[DT Alignment] Applied dt-col-right to col", i,
                  "- sortCell has class:", $sortCell.hasClass("dt-col-right"),
                  "- filterCell has class:", $filterCell.hasClass("dt-col-right"));
              }
            });
          });
        }catch(e){ console.warn("applyColumnAlignments error:", e); }
      }

      // Find the column index for "Section" (to place filter controls above it)
      function findSectionColumnIndex(heads){
        try{
          var $labelRow = heads.$theadVis.find("tr:not(.dt-sort-row):not(.dt-filter-row):last th");
          var sectionIdx = -1;
          $labelRow.each(function(i){
            var colName = $(this).text().trim().toLowerCase();
            if (colName === "section") {
              sectionIdx = i;
              return false; // break
            }
          });
          return sectionIdx;
        }catch(e){ return -1; }
      }

      function ensureFilterControls(heads){
        try{
          // Find Section column index - place controls above it
          var sectionIdx = findSectionColumnIndex(heads);

          heads.$theads.each(function(){
            var $h = $(this);
            var $filterCells = $h.find("tr.dt-filter-row th");
            if (!$filterCells.length) return;

            // Remove any existing filter controls first
            $h.find(".dt-filter-controls").remove();

            // Determine which cell to put controls in
            // If Section column exists, put controls there; otherwise use first column
            var targetIdx = (sectionIdx >= 0 && sectionIdx < $filterCells.length) ? sectionIdx : 0;
            var $targetTh = $filterCells.eq(targetIdx);

            var html = [
              \'<span class="dt-filter-controls" style="white-space:nowrap;display:block;margin-bottom:2px;">\',
              \'<a href="#" class="dt-apply-filters" title="Apply all column filters" style="font-size:11px;text-decoration:none;margin-right:6px;">✔ apply</a>\',
              \'<a href="#" class="dt-clear-filters" title="Clear all column filters" style="font-size:11px;text-decoration:none;">✖ clear filters</a>\',
              \'</span>\'
            ].join("");
            $targetTh.prepend(html);
          });
        }catch(e){}
      }

      // Split camelCase and concatenated words in header labels for wrapping
      function splitHeaderLabels(heads){
        try{
          // Process ALL theads (including scroll head copies)
          heads.$theads.each(function(){
            var $thead = $(this);
            var $labelRow = $thead.find("tr:not(.dt-sort-row):not(.dt-filter-row) th");
            $labelRow.each(function(){
              var $th = $(this);
              // Skip if already processed
              if ($th.data("split-done")) return;
              $th.data("split-done", true);

              var text = $th.text().trim();
              // Split camelCase: "ObjectName" -> "Object Name"
              // Split on capital letters: insert space before caps that follow lowercase
              var split = text.replace(/([a-z])([A-Z])/g, "$1 $2");
              // Also handle "ProjectionDate" style
              split = split.replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2");

              if (split !== text) {
                $th.text(split);
              }
            });
          });
        }catch(e){ console.warn("splitHeaderLabels error:", e); }
      }

      function ensureClearSort(heads){
        try{
          heads.$theads.each(function(){
            var $h = $(this);
            var $firstTh = $h.find("tr.dt-sort-row th").first();
            if (!$firstTh.length) return;
            if ($firstTh.find(".dt-clear-sort").length) return;
            var $a = $(\'<a href="#" class="dt-clear-sort" title="Clear all sorting" style="margin-left:8px; font-size:11px; text-decoration:none;">✖ clear</a>\');
            $firstTh.append($a);
          });
        }catch(e){}
      }

      function rebuild(){
        var heads = locateHeads(); if (!heads.$theadVis.length) return;
        heads.$theads.addClass("dtadv-owner-" + id);

        // Split camelCase header labels for wrapping (e.g. ObjectName -> Object Name)
        splitHeaderLabels(heads);

        // Resolve RAW filter inputs to persist:
        var cachedRaw = getSavedRawFilters();
        if (!cachedRaw) {
          // try to read from the current visible thead before we nuke it
          cachedRaw = readInputsFromVisibleHead(heads);
        }
        // last resort: API (regex strings) – not ideal but prevents losing everything
        if (!cachedRaw) {
          cachedRaw = readFilterValsFromApi();
        }

        // remove old helper rows
        heads.$theads.find("tr.dt-sort-row, tr.dt-filter-row").remove();

        // build per-<thead> using its live column count
        heads.$theads.each(function(){
          var $h = $(this);
          var n  = $h.find("tr:last th").length;
          if (!n) n = api.columns().count();
          var rows = buildRows(n);
          $h.prepend(rows.$frow); $h.prepend(rows.$srow);
        });

        var ns = ".dtadv."+id;

        // sort clicks — multi-order stack with position badges
        $(document).off("click"+ns, "thead.dtadv-owner-"+id+" tr.dt-sort-row .dt-sortbtn")
          .on("click"+ns, "thead.dtadv-owner-"+id+" tr.dt-sort-row .dt-sortbtn", function(e){
            e.preventDefault(); e.stopPropagation();
            var $btn = $(this), dir = $btn.attr("data-dir");
            var visIdx = $btn.closest("th").index();
            var colIdx = api.column(visIdx + ":visible").index();

            sortStack = sortStack.filter(function(x){ return x.colIdx !== colIdx; });
            if (dir !== "none") sortStack.push({ colIdx: colIdx, dir: dir });

            var orders = sortStack.map(function(x){ return [x.colIdx, x.dir]; });
            api.order(orders).draw(false);
            renderBadges(heads);
          });

        // filters — apply on Enter (simple text search, no regex to avoid numeric column issues)
        $(document).off("keydown"+ns, "thead.dtadv-owner-"+id+" tr.dt-filter-row input.dt-filter-input")
          .on("keydown"+ns, "thead.dtadv-owner-"+id+" tr.dt-filter-row input.dt-filter-input", function(e){
            if (e.key === "Enter"){
              var $thead = $(this).closest("thead");
              var i = parseInt($(this).attr("data-col"),10);
              var raw = this.value || "";
              saveRawFiltersFromHead($thead);
              var term = buildSearchTerm(raw);
              // Use simple text search (regex=FALSE, smart=TRUE, case-insensitive=TRUE)
              api.column(i).search(term, false, true, true);
              api.draw(false);
              setTimeout(function(){ writeRawFilterInputs(locateHeads(), getSavedRawFilters()); }, 0);
              e.preventDefault();
            }
          });

        // Detect and apply column alignments (right-align numeric columns)
        var alignments = detectColumnAlignments(heads);
        console.log("[DT Alignment] Detected alignments:", alignments);
        applyColumnAlignments(heads, alignments);

        // Re-apply alignments after delays to ensure they stick
        function reapplyAlignments(){
          var h = locateHeads();
          var a = detectColumnAlignments(h);
          applyColumnAlignments(h, a);
        }
        setTimeout(reapplyAlignments, 100);
        setTimeout(reapplyAlignments, 300);
        setTimeout(reapplyAlignments, 600);

        // Add filter controls (positioned above Section column), then restore cached RAW values to inputs
        ensureFilterControls(heads);
        writeRawFilterInputs(heads, cachedRaw);

        // Clear-all-sorting control
        ensureClearSort(heads);
        $(document).off("click"+ns, "thead.dtadv-owner-"+id+" .dt-clear-sort")
          .on("click"+ns, "thead.dtadv-owner-"+id+" .dt-clear-sort", function(e){
            e.preventDefault();
            sortStack = [];
            api.order([]).draw(false);
            setTimeout(function(){ renderBadges(locateHeads()); }, 0);
          });

        // Apply all filters (simple text search)
        $(document).off("click"+ns, "thead.dtadv-owner-"+id+" .dt-apply-filters")
          .on("click"+ns, "thead.dtadv-owner-"+id+" .dt-apply-filters", function(e){
            e.preventDefault();
            var $thead = $(this).closest("thead");
            var rawVals = [];
            $thead.find("tr.dt-filter-row th input.dt-filter-input").each(function(i){ rawVals[i] = this.value || ""; });
            // Save RAW values
            $cont.data(KEY_FILTERS, rawVals);
            // Apply as simple text search (no regex to avoid numeric column issues)
            api.columns(":visible").every(function(vidx){
              var raw = rawVals[vidx] || "";
              var term = buildSearchTerm(raw);
              // Use simple text search (regex=FALSE, smart=TRUE, case-insensitive=TRUE)
              this.search(term, false, true, true);
            });
            api.draw(false);
            setTimeout(function(){ writeRawFilterInputs(locateHeads(), getSavedRawFilters()); }, 0);
          });

        $(document).off("click"+ns, "thead.dtadv-owner-"+id+" .dt-clear-filters")
          .on("click"+ns, "thead.dtadv-owner-"+id+" .dt-clear-filters", function(e){
            e.preventDefault();
            $cont.data(KEY_FILTERS, []); // clear saved RAW
            try { api.search(""); } catch(_){}
            api.columns().every(function(){ this.search(""); });
            api.draw(false);
            try { var g = $cont.find("div.dataTables_filter input[type=search]"); if (g.length) g.val(""); } catch(_){}
            setTimeout(function(){ writeRawFilterInputs(locateHeads(), getSavedRawFilters()); }, 0);
          });

        // Recompute widths → adjust FixedHeader → lock helper widths
        try { api.columns.adjust(); } catch(_) {}
        try { if (api.fixedHeader) api.fixedHeader.adjust(); } catch(_) {}

        // Multiple delayed calls to ensure alignment after all rendering completes
        var syncWidths = function(){
          var h = locateHeads();
          lockTableLayout(h);
          syncFilterWidths(h);
        };
        
        syncWidths();
        setTimeout(syncWidths, 0);
        setTimeout(syncWidths, 50);
        setTimeout(syncWidths, 150);
        setTimeout(syncWidths, 300);
        setTimeout(syncWidths, 500);
        
        renderBadges(heads);
      }

      // Initial build
      rebuild();

      // Event hooks (hardened)
      var nsWin = "resize.dtadv."+id;
      api.off(".dtadv")
        .on("draw.dt.dtadv",               function(){ rebuild(); })
        .on("column-reorder.dt.dtadv",     function(){ setTimeout(rebuild, 0); })
        .on("column-visibility.dt.dtadv",  function(){ setTimeout(rebuild, 0); })
        .on("responsive-resize.dt.dtadv",  function(){ setTimeout(rebuild, 0); })
        .on("destroy.dt.dtadv",            function(){ $(window).off(nsWin); $(document).off(".dtadv."+id); });

      $(window).off(nsWin).on(nsWin, function(){ setTimeout(rebuild, 60); });
      api.on("draw.dt.dtadvWin", function(){
        $(window).off(nsWin).on(nsWin, function(){ setTimeout(rebuild, 60); });
      });

    } catch(e) { console.error("DT Adv Init error:", e); }
  };
};

/* -------- Combined wrapper (adv header + page jumper) --------------------- */
window.dtAdvInitWithJumper = function(){
  var adv    = (window.dtAdvInit && window.dtAdvInit()) || function(){};
  var jumper = (window.dtAddPageJumper && window.dtAddPageJumper()) || function(){};
  return function(settings){ try{ adv(settings); }catch(e){} try{ jumper(settings); }catch(e){} };
};

/* -------- STRIP ALL WIDTHS - DISABLED - let DataTables autoWidth handle sizing ----- */
function stripTableWidths(tableId) {
  // DISABLED: Let DataTables autoWidth calculate column widths
  // Stripping widths was breaking the scroll bars and preventing proper column sizing
  return;
}

/* -------- GLOBAL HOOK: Auto-apply advanced features to ALL DataTables ----- */
$(document).on("preInit.dt", function(e, settings){
  console.log("[JS] DataTable preInit.dt fired");
  // This fires BEFORE each DataTable is fully initialized
  // We hook into init.dt to apply our advanced features AFTER initialization
  var api = new $.fn.dataTable.Api(settings);
  api.on("init.dt", function(){
    console.log("[JS] DataTable init.dt fired - applying advanced features");
    try {
      var combo = window.dtAdvInitWithJumper ? window.dtAdvInitWithJumper() : null;
      if (combo) combo(settings);
    } catch(err) {
      console.warn("dtAdvInitWithJumper error:", err);
    }

    // Strip widths after init - let CSS control sizing
    var tableId = settings.sTableId;
    if (tableId) {
      setTimeout(function(){ stripTableWidths(tableId); }, 0);
      setTimeout(function(){ stripTableWidths(tableId); }, 100);
      setTimeout(function(){ stripTableWidths(tableId); }, 300);
    }
  });

  // Re-strip widths after every draw (pagination, filtering, etc.)
  api.on("draw.dt", function(){
    var tableId = settings.sTableId;
    if (tableId) {
      setTimeout(function(){ stripTableWidths(tableId); }, 0);
    }
  });
});
'
