# R/73_server_results.R — Server results table rendering

register_results_server <- function(input, output, session, results_obj, uploaded_df) {

  # >>> BEGIN PATCH A: RESULTS RENDERER (add in server, after output$preview_card) <<<
  output$results_tabs_ui <- renderUI({
    res <- results_obj()
    if (is.null(res)) {
      return(HTML("<span style='color:red; font-weight:bold;'>&lt;&lt;&lt; Run analysis to see results.</span>"))
    }

    # helper: render multi-line headers ("\n" -> "<br>")
    hdr <- function(nms) gsub("\n", "<br>", nms, fixed = TRUE)

    make_dt <- function(df, sheet) {
      # --- RAW: FAST MODE (server-side, paged, minimal styling) ---
      if (sheet %in% c(SHEET_NAMES$raw, "AvEMRGActualsExpecteds")) {
        n <- nrow(df)
        FAST <- isTRUE(n >= 30000)  # adjust threshold as needed

        # strip factors to avoid heavy coercions
        df[] <- lapply(df, function(col) if (is.factor(col)) as.character(col) else col)

        # (optional) truncate ultra-large tables for browser responsiveness
        # if (FAST && n > 200000) {
        #   showNotification(
        #     sprintf("RAW truncated to first 200,000 rows for speed (had %s). Use Download to get full.", scales::comma(n)),
        #     type = "warning", duration = 8
        #   )
        #   df <- utils::head(df, 200000)
        # }

        dt <- DT::datatable(
          df,
          rownames = FALSE,
          escape   = FALSE,
          options = list(
            deferRender = TRUE,
            scrollX     = TRUE,
            scroller    = FAST,              # virtual scrolling for big tables
            paging      = TRUE,
            pageLength  = if (FAST) 50 else 100,
            lengthMenu  = list(c(25,50,100,200,500,1000), c(25,50,100,200,500,1000)),
            searchDelay = 400,
            autoWidth   = TRUE,     # Auto-size columns to fit content
            ordering    = TRUE,
            fixedHeader = TRUE
          ),
          class = "stripe hover compact",
          colnames = hdr(names(df))
        )

        # Very light numeric formatting on key columns only
        if ("Accident Period" %in% names(df)) dt <- DT::formatRound(dt, "Accident Period", digits = 1, mark = "")
        if ("Accident Year"   %in% names(df)) dt <- DT::formatRound(dt, "Accident Year",   digits = 0, mark = "")

        # Avoid per-cell currency/colour formatting here (too expensive on large RAW)
        return(dt)
      }

      # --- Total Summary: amounts vs % formatting ---
      if (identical(sheet, "Total Summary") && nrow(df)) {
        yrs <- ts_year_cols(df)
        value_cols <- c(as.character(yrs), "Grand Total")
        is_pct_row <- (df$`A vs E` == "%")

        fmt_cell <- function(v, is_pct) {
          vnum <- suppressWarnings(as.numeric(v))
          if (is.na(vnum)) return("<div style='text-align:right'></div>")
          s <- if (is_pct) sprintf("%.1f%%", vnum * 100) else sprintf("%.2f", vnum)
          col <- if (!is.na(vnum) && vnum < 0) "red" else "black"
          sprintf("<div style='text-align:right;color:%s'>%s</div>", col, s)
        }

        disp <- df
        for (cn in value_cols) {
          vals <- df[[cn]]
          out  <- character(nrow(df))
          if (any(is_pct_row))   out[ is_pct_row] <- vapply(vals[ is_pct_row], fmt_cell, character(1), is_pct = TRUE)
          if (any(!is_pct_row))  out[!is_pct_row] <- vapply(vals[!is_pct_row], fmt_cell, character(1), is_pct = FALSE)
          disp[[cn]] <- out
        }

        targets <- which(names(df) %in% value_cols) - 1
        return(DT::datatable(
          disp,
          options = list(
            scrollX = TRUE, paging = FALSE, searching = FALSE, info = FALSE, ordering = FALSE,
            columnDefs = list(list(className = "dt-right", targets = targets))
          ),
          rownames = FALSE, escape = FALSE, colnames = hdr(names(df))
        ))
      }

      # --- All other sheets (default formatting) ---
      dt <- DT::datatable(
        df,
        options = list(scrollX = TRUE, pageLength = 25),
        rownames = FALSE, escape = FALSE, colnames = hdr(names(df))
      )

      num_cols <- names(df)[sapply(df, is.numeric)]
      if (length(num_cols)) {
        if (grepl("pct$", sheet, ignore.case = TRUE)) {
          dt <- DT::formatPercentage(dt, columns = num_cols, digits = 1)
        } else {
          dt <- DT::formatRound(dt, columns = num_cols, digits = 1)
        }
        dt <- DT::formatStyle(dt, columns = num_cols,
                              color = DT::styleInterval(c(-1e-12, 0), c("red","black","black")))
      }

      # AvE conditional fill for year/GT columns
      AVE_SHEETS <- c(
        SHEET_NAMES$paid_ave, SHEET_NAMES$incurred_ave,
        "Paid AvE","Incurred AvE",
        "Paid A v E – NIG","Paid A v E – Non NIG",
        "Incurred A v E – NIG","Incurred A v E – Non NIG"
      )
      if (sheet %in% AVE_SHEETS && length(num_cols)) {
        yr_cols <- intersect(num_cols, c(as.character(ts_year_cols(df)), "Grand Total"))
        if (length(yr_cols)) {
          dt <- DT::formatStyle(
            dt, columns = yr_cols,
            backgroundColor = DT::styleInterval(c(-2.5, 2.5), c(COL_GOOD_AE, "#FFFFFF", COL_BAD_AE))
          )
        }
      }
      dt
    } # end make_dt

    # Build panels (UI only; the DTs will be bound lazily below)
    panels <- purrr::map(names(res), function(sheet) {
      out_id <- paste0("tbl_", stringr::str_replace_all(substr(sheet, 1, 60), " ", "_"))
      nav_panel(sheet, card(
        style = "min-height:600px; max-height:2000px;",
        DTOutput(out_id)
      ))
    })

    # Lazy-bind each table so it renders only when its tab is selected
    purrr::walk(names(res), function(sheet_nm) {
      out_id <- paste0("tbl_", stringr::str_replace_all(substr(sheet_nm, 1, 60), " ", "_"))
      local({
        sid <- out_id
        nm  <- sheet_nm
        df  <- res[[nm]]
        output[[sid]] <- renderDT({
          req(input$tabs_results_inner == nm)   # only build when visible
          make_dt(df, nm)
        }, server = TRUE)
      })
    })

    # Return the inner tabset that the lazy req() listens to
    do.call(navset_tab, c(panels, list(id = "tabs_results_inner")))
  })

  # >>> END PATCH A <<<

  # Minimal "Input Data" card so uiOutput('preview_card') works
  output$preview_card <- renderUI({
    df <- uploaded_df()
    if (is.null(df) || nrow(df) == 0) {
      return(div(
        class = "p-3",
        HTML("<span style='color:red; font-weight:bold;'>&lt;&lt;&lt; Upload a CSV to preview data. (Use Browse Button)</span>")
      ))
    }
    # Card with fit-content width to shrink columns to data
    tagList(
      tags$style(HTML("
        #preview-data-card {
          width: fit-content !important;
          max-width: 100% !important;
          min-height: 200px;
        }
        #preview-data-card .card-body {
          display: block !important;
          width: auto !important;
          overflow-x: auto !important;
        }
      ")),
      card(
        id = "preview-data-card",
        card_header("Uploaded Data"),
        DTOutput("tbl_preview")
      )
    )
  })
}
