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
        // Controls row (apply/clear filters) - sits ABOVE sort row
        var $crow = $("<tr class=\\"dt-controls-row\\"></tr>");
        var $srow = $("<tr class=\\"dt-sort-row\\"></tr>");
        var $frow = $("<tr class=\\"dt-filter-row\\"></tr>");
        for (var i=0;i<n;i++){
          // Controls row cell (only first cell has content, rest are empty)
          var $thC = $("<th></th>");
          $crow.append($thC);

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
        return {$crow:$crow, $srow:$srow, $frow:$frow};
      }

      // ---- Filter search with wildcard support ----
      // Supports: * (any chars), ? (single char), % (SQL-style, same as *)
      // For OR support: "NIG;DLI" is handled by searching for each term
      // Returns {term: string, isRegex: boolean}
      function buildSearchTerm(raw){
        if (!raw) return {term: "", isRegex: false};
        var trimmed = raw.trim();
        if (!trimmed) return {term: "", isRegex: false};

        // Check if wildcards are present
        var hasWildcard = /[*?%]/.test(trimmed);

        if (!hasWildcard) {
          // No wildcards - use simple text search
          return {term: trimmed, isRegex: false};
        }

        // Convert wildcard syntax to regex
        // First, escape regex special chars (except our wildcards)
        var escaped = trimmed.replace(/([.+^${}()|[\\]\\\\])/g, "\\\\$1");

        // Handle semicolon-separated OR values with wildcards
        var parts = escaped.split(";").map(function(part){
          part = part.trim();
          if (!part) return null;
          // Convert wildcards: * and % -> .*, ? -> .
          part = part.replace(/\\*/g, ".*");
          part = part.replace(/%/g, ".*");
          part = part.replace(/\\?/g, ".");
          return part;
        }).filter(function(p){ return p !== null; });

        if (parts.length === 0) return {term: "", isRegex: false};
        if (parts.length === 1) {
          return {term: parts[0], isRegex: true};
        }
        // Multiple parts - join with OR
        return {term: "(" + parts.join("|") + ")", isRegex: true};
      }

      // ---- Numeric column filter formatting for DT server-side ----
      // DT's server-side filterRange() expects "min ... max" format for numeric columns
      // Supports: exact value, >=, <=, >, <, and range (e.g., "100..200" or "100-200")
      // Returns {term: string, isNumericRange: boolean}
      function buildNumericSearchTerm(raw){
        if (!raw) return {term: "", isNumericRange: false};
        var trimmed = raw.trim();
        if (!trimmed) return {term: "", isNumericRange: false};

        // Range operators: "100..200", "100...200", "100-200" (but not negative like "-100")
        var rangeMatch = trimmed.match(/^(-?[\\d.]+)\\s*(?:\\.\\.\\.?|\\s+to\\s+|\\s*-\\s*(?=[\\d]))\\s*(-?[\\d.]+)$/i);
        if (rangeMatch) {
          var min = parseFloat(rangeMatch[1]);
          var max = parseFloat(rangeMatch[2]);
          if (!isNaN(min) && !isNaN(max)) {
            // Ensure min <= max
            if (min > max) { var tmp = min; min = max; max = tmp; }
            return {term: min + " ... " + max, isNumericRange: true};
          }
        }

        // Greater than or equal: ">=100", ">= 100"
        var gteMatch = trimmed.match(/^>=\\s*(-?[\\d.]+)$/);
        if (gteMatch) {
          var val = parseFloat(gteMatch[1]);
          if (!isNaN(val)) {
            // Use very large max for unbounded upper range
            return {term: val + " ... " + 1e308, isNumericRange: true};
          }
        }

        // Less than or equal: "<=100", "<= 100"
        var lteMatch = trimmed.match(/^<=\\s*(-?[\\d.]+)$/);
        if (lteMatch) {
          var val = parseFloat(lteMatch[1]);
          if (!isNaN(val)) {
            // Use very small min for unbounded lower range
            return {term: -1e308 + " ... " + val, isNumericRange: true};
          }
        }

        // Greater than: ">100", "> 100"
        var gtMatch = trimmed.match(/^>\\s*(-?[\\d.]+)$/);
        if (gtMatch) {
          var val = parseFloat(gtMatch[1]);
          if (!isNaN(val)) {
            // Add tiny epsilon to exclude the exact value
            return {term: (val + 1e-10) + " ... " + 1e308, isNumericRange: true};
          }
        }

        // Less than: "<100", "< 100"
        var ltMatch = trimmed.match(/^<\\s*(-?[\\d.]+)$/);
        if (ltMatch) {
          var val = parseFloat(ltMatch[1]);
          if (!isNaN(val)) {
            // Subtract tiny epsilon to exclude the exact value
            return {term: -1e308 + " ... " + (val - 1e-10), isNumericRange: true};
          }
        }

        // Exact numeric value: "100", "100.5", "-50"
        var numMatch = trimmed.match(/^-?[\\d.]+$/);
        if (numMatch) {
          var val = parseFloat(trimmed);
          if (!isNaN(val)) {
            // For exact match, use same value for min and max
            return {term: val + " ... " + val, isNumericRange: true};
          }
        }

        // Not a recognized numeric pattern - return as text (will likely fail but let DT handle it)
        return {term: trimmed, isNumericRange: false};
      }

      // Check if a column is numeric based on column name or data inspection
      function isNumericColumn(colIndex, heads){
        try {
          // Get column name from header
          var $labelRow = heads.$theadVis.find("tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row):last th");
          var colName = $labelRow.eq(colIndex).text().trim().toLowerCase();

          // Known numeric columns
          var numericCols = ["actual", "expected", "a - e", "a-e", "accident period", "accidentperiod",
                           "accident year", "accidentyear", "amount", "value", "count", "total",
                           "grand total", "grandtotal"];

          // Check if column name matches known numeric columns
          var isKnownNumeric = numericCols.some(function(nc){ return colName.indexOf(nc) >= 0; });

          // Check if column name is a year (e.g., 2010, 2011)
          var isYearCol = /^[0-9]{4}$/.test(colName.trim());

          if (isKnownNumeric || isYearCol) {
            console.log("[DT Filter] Column", colIndex, "("+colName+") detected as numeric");
            return true;
          }

          // Fallback: check actual data content
          var $bodyTable = $cont.find("div.dataTables_scrollBody table.dataTable");
          if (!$bodyTable.length) $bodyTable = $tbl;
          var $rows = $bodyTable.find("tbody tr").slice(0, 5);
          var numericCount = 0;
          var totalChecked = 0;

          $rows.each(function(){
            var $cell = $(this).find("td").eq(colIndex);
            if ($cell.length) {
              var val = $cell.text().trim();
              // Remove formatting chars and check if numeric
              var cleaned = val.replace(/[,$£€%()\\s]/g, "").replace(/^-/, "");
              totalChecked++;
              if (/^[\\d.]+$/.test(cleaned) && cleaned.length > 0) {
                numericCount++;
              }
            }
          });

          var isDataNumeric = totalChecked > 0 && (numericCount / totalChecked) > 0.7;
          if (isDataNumeric) {
            console.log("[DT Filter] Column", colIndex, "("+colName+") detected as numeric from data");
          }
          return isDataNumeric;
        } catch(e) {
          console.warn("[DT Filter] isNumericColumn error:", e);
          return false;
        }
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

      function lockHelperColWidths(heads){
        try{
          // DISABLED: Let CSS handle column widths with table-layout: auto
          // This function was locking widths which prevented columns from shrinking to content
          // The sort/filter rows will inherit widths naturally from the table layout
          return;
        }catch(e){ console.warn("lockHelperColWidths error:", e); }
      }

      function syncFilterWidths(heads){
        try{
          // DISABLED: Let CSS handle filter input widths
          // This function was setting fixed widths which forced column expansion
          return;
        } catch(e){}
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
          // Get column names from header labels (exclude helper rows)
          var $labelRow = heads.$theadVis.find("tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row):last th");
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

      // Find the column index for "Section" (not currently used, but kept for potential future use)
      function findSectionColumnIndex(heads){
        try{
          var $labelRow = heads.$theadVis.find("tr:not(.dt-sort-row):not(.dt-filter-row):not(.dt-controls-row):last th");
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
          heads.$theads.each(function(){
            var $h = $(this);
            var $controlsCells = $h.find("tr.dt-controls-row th");
            if (!$controlsCells.length) return;

            // Remove any existing filter controls first
            $h.find(".dt-filter-controls").remove();

            // Place controls in the first cell of the controls row
            var $targetTh = $controlsCells.eq(0);

            var html = [
              \'<span class="dt-filter-controls" style="white-space:nowrap;">\',
              \'<a href="#" class="dt-apply-filters" title="Apply all column filters" style="font-size:11px;text-decoration:none;margin-right:6px;">✔ apply</a>\',
              \'<a href="#" class="dt-clear-filters" title="Clear all column filters" style="font-size:11px;text-decoration:none;">✖ clear filters</a>\',
              \'</span>\'
            ].join("");

            $targetTh.html(html);
          });
        }catch(e){}
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
        heads.$theads.find("tr.dt-controls-row, tr.dt-sort-row, tr.dt-filter-row").remove();

        // build per-<thead> using its live column count
        heads.$theads.each(function(){
          var $h = $(this);
          var n  = $h.find("tr:last th").length;
          if (!n) n = api.columns().count();
          var rows = buildRows(n);
          // Order: controls row (top), sort row, filter row, then original header row
          $h.prepend(rows.$frow); $h.prepend(rows.$srow); $h.prepend(rows.$crow);
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
            renderBadges(locateHeads());

            // Force columns to shrink after sort (multiple delays to catch async recalculations)
            setTimeout(function(){ forceColumnsToShrink(id); }, 0);
            setTimeout(function(){ forceColumnsToShrink(id); }, 50);
            setTimeout(function(){ forceColumnsToShrink(id); }, 150);
            setTimeout(function(){ forceColumnsToShrink(id); }, 300);
            setTimeout(function(){ forceColumnsToShrink(id); }, 500);
          });

        // filters — apply on Enter (supports wildcards for text, numeric ranges for numeric columns)
        $(document).off("keydown"+ns, "thead.dtadv-owner-"+id+" tr.dt-filter-row input.dt-filter-input")
          .on("keydown"+ns, "thead.dtadv-owner-"+id+" tr.dt-filter-row input.dt-filter-input", function(e){
            if (e.key === "Enter"){
              var $thead = $(this).closest("thead");
              var i = parseInt($(this).attr("data-col"),10);
              var raw = this.value || "";
              saveRawFiltersFromHead($thead);

              // Check if this is a numeric column - if so, use range format for server-side filtering
              var heads = locateHeads();
              var isNumeric = isNumericColumn(i, heads);

              if (isNumeric && raw.trim()) {
                // Use numeric range format for DT server-side filterRange()
                var numSearchObj = buildNumericSearchTerm(raw);
                console.log("[DT Filter] Numeric column", i, "raw:", raw, "formatted:", numSearchObj.term);
                // For numeric columns, use the range format directly (no regex, no smart search)
                api.column(i).search(numSearchObj.term, false, false, true);
              } else {
                // Use text/wildcard search for non-numeric columns
                var searchObj = buildSearchTerm(raw);
                // search(term, regex, smart, caseInsensitive)
                api.column(i).search(searchObj.term, searchObj.isRegex, !searchObj.isRegex, true);
              }
              api.draw(false);
              setTimeout(function(){ writeRawFilterInputs(locateHeads(), getSavedRawFilters()); }, 0);
              // Force columns to shrink after filter Enter
              setTimeout(function(){ forceColumnsToShrink(id); }, 0);
              setTimeout(function(){ forceColumnsToShrink(id); }, 50);
              setTimeout(function(){ forceColumnsToShrink(id); }, 150);
              setTimeout(function(){ forceColumnsToShrink(id); }, 300);
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
            // Force columns to shrink after clear sort
            setTimeout(function(){ forceColumnsToShrink(id); }, 0);
            setTimeout(function(){ forceColumnsToShrink(id); }, 50);
            setTimeout(function(){ forceColumnsToShrink(id); }, 150);
            setTimeout(function(){ forceColumnsToShrink(id); }, 300);
          });

        // Apply all filters (supports wildcards for text, numeric ranges for numeric columns)
        $(document).off("click"+ns, "thead.dtadv-owner-"+id+" .dt-apply-filters")
          .on("click"+ns, "thead.dtadv-owner-"+id+" .dt-apply-filters", function(e){
            e.preventDefault();
            var $thead = $(this).closest("thead");
            var rawVals = [];
            $thead.find("tr.dt-filter-row th input.dt-filter-input").each(function(i){ rawVals[i] = this.value || ""; });
            // Save RAW values
            $cont.data(KEY_FILTERS, rawVals);
            // Apply filters with numeric range support for numeric columns
            var heads = locateHeads();
            api.columns(":visible").every(function(vidx){
              var raw = rawVals[vidx] || "";
              var isNumeric = isNumericColumn(vidx, heads);

              if (isNumeric && raw.trim()) {
                // Use numeric range format for DT server-side filterRange()
                var numSearchObj = buildNumericSearchTerm(raw);
                console.log("[DT Filter] Apply: Numeric column", vidx, "raw:", raw, "formatted:", numSearchObj.term);
                this.search(numSearchObj.term, false, false, true);
              } else {
                // Use text/wildcard search for non-numeric columns
                var searchObj = buildSearchTerm(raw);
                this.search(searchObj.term, searchObj.isRegex, !searchObj.isRegex, true);
              }
            });
            api.draw(false);
            setTimeout(function(){ writeRawFilterInputs(locateHeads(), getSavedRawFilters()); }, 0);
            // Force columns to shrink after filter apply
            setTimeout(function(){ forceColumnsToShrink(id); }, 0);
            setTimeout(function(){ forceColumnsToShrink(id); }, 50);
            setTimeout(function(){ forceColumnsToShrink(id); }, 150);
            setTimeout(function(){ forceColumnsToShrink(id); }, 300);
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
            // Force columns to shrink after filter clear
            setTimeout(function(){ forceColumnsToShrink(id); }, 0);
            setTimeout(function(){ forceColumnsToShrink(id); }, 50);
            setTimeout(function(){ forceColumnsToShrink(id); }, 150);
            setTimeout(function(){ forceColumnsToShrink(id); }, 300);
          });

        // Recompute widths → adjust FixedHeader → lock helper widths
        try { api.columns.adjust(); } catch(_) {}
        try { if (api.fixedHeader) api.fixedHeader.adjust(); } catch(_) {}

        // Multiple delayed calls to ensure alignment after all rendering completes
        var syncWidths = function(){
          var h = locateHeads();
          lockHelperColWidths(h);
          syncFilterWidths(h);
        };
        
        syncWidths();
        setTimeout(syncWidths, 0);
        setTimeout(syncWidths, 50);
        setTimeout(syncWidths, 150);
        setTimeout(syncWidths, 300);
        setTimeout(syncWidths, 500);
        
        renderBadges(heads);
        
        // Update FixedHeader to include the new header rows (sort buttons, filters)
        setTimeout(function(){
          try {
            if (api.fixedHeader) {
              api.fixedHeader.update();
            }
          } catch(e) { console.warn("FixedHeader update error:", e); }
        }, 100);
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

/* -------- FORCE COLUMNS TO SHRINK: Strip width-related inline styles ----- */
function forceColumnsToShrink(tableId) {
  try {
    var $tbl = $("#" + tableId);
    if (!$tbl.length) return;

    // Remove colgroup entirely - it forces column widths
    $tbl.find("colgroup").remove();

    // Get wrapper to check if we are in freeze-pane mode
    var $wrapper = $("#" + tableId + "_wrapper");
    var isFreezePaneMode = $wrapper.closest(".freeze-pane").length > 0;

    // Remove DataTables inline width from table element - let CSS handle it
    // But preserve table-layout property
    var tableLayout = $tbl.css("table-layout");
    $tbl.css("width", "").css("min-width", "");
    if (tableLayout) $tbl.css("table-layout", tableLayout);

    // Strip width attributes from th cells but preserve text-align for right-aligned columns
    $tbl.find("th").each(function() {
      var $th = $(this);
      var textAlign = $th.css("text-align");
      $th.css("width", "").removeAttr("width");
      if (textAlign === "right") {
        $th.css("text-align", "right");
      }
    });

    // Strip width from td cells BUT preserve background-color and color for A-E coloring
    $tbl.find("td").each(function() {
      var $td = $(this);
      var bgColor = $td.css("background-color");
      var textColor = $td.css("color");
      $td.css("width", "").removeAttr("width");
      // Restore A-E coloring if it was set (non-default colors)
      if (bgColor && bgColor !== "rgba(0, 0, 0, 0)" && bgColor !== "transparent" && bgColor !== "rgb(255, 255, 255)") {
        $td.css("background-color", bgColor);
      }
      if (textColor && textColor !== "rgb(0, 0, 0)" && textColor !== "rgb(33, 37, 41)") {
        $td.css("color", textColor);
      }
    });

    // For freeze-pane mode: DO NOT strip styles from scroll containers
    // The scroll containers need their height/overflow styles for freeze panes to work
    if (!isFreezePaneMode) {
      // Only strip width-related styles from wrapper for non-freeze-pane tables
      if ($wrapper.length) {
        $wrapper.css("width", "");
      }
    }

    // NEVER strip styles from scroll containers - they control freeze pane behavior
    // The height and overflow properties must be preserved

  } catch(e) {
    console.warn("[Column Shrink] Error:", e);
  }
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

    // Force columns to shrink after all other init is done
    var tableId = settings.sTableId;
    if (tableId) {
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 0);
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 100);
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 300);
    }
  });

  // Also strip widths after every draw (multiple delays to catch async recalculations)
  api.on("draw.dt", function(){
    var tableId = settings.sTableId;
    if (tableId) {
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 0);
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 50);
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 150);
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 300);
      setTimeout(function(){ forceColumnsToShrink(tableId); }, 500);
    }
  });
});
'
