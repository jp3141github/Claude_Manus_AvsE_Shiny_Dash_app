# R/70_server_upload.R — Server upload handling and preview

register_upload_server <- function(input, output, session, uploaded_df) {

  # ---- Upload handling (as in first script) + preview formatting ----
  observe({
    fi <- input$csv_file; if (is.null(fi)) return()
    datapath <- fi$datapath

    # Wrap upload processing in progress indicator
    withProgress(message = 'Processing upload', value = 0, {
      # Step 1: Reading file (40%)
      file_size_mb <- round(file.size(datapath) / 1024^2, 1)
      incProgress(0.2, detail = sprintf("Reading file (%s MB)...", file_size_mb))

      df <- tryCatch({
        ext <- tolower(fs::path_ext(datapath))
        if (ext %in% c("xlsx","xlsm","xls")) readxl::read_excel(datapath) %>% as.data.frame(stringsAsFactors = FALSE)
        else tryCatch(readr::read_csv(datapath, show_col_types = FALSE) %>% as.data.frame(),
                      error = function(e) readr::read_csv(datapath, show_col_types = FALSE,
                                                          locale = readr::locale(decimal_mark=".", grouping_mark=",")) %>% as.data.frame())
      }, error = function(e) readr::read_csv(datapath, show_col_types = FALSE) %>% as.data.frame())

      incProgress(0.2, detail = sprintf("Loaded %s rows, %s columns", format(nrow(df), big.mark = ","), ncol(df)))
      uploaded_df(df)

      # Step 2: Populating controls (70%)
      incProgress(0.3, detail = "Populating controls...")
      # Populate selectors (Model Type, Projection Date)
      if ("Model Type" %in% names(df)) {
        mt_choices <- sort(unique(stats::na.omit(as.character(df[["Model Type"]]))))
        sel_mt <- if ("Proxy" %in% mt_choices) "Proxy" else character(0)
        updateSelectizeInput(session, "model_type", choices = mt_choices, server = TRUE, selected = sel_mt)
      } else updateSelectizeInput(session, "model_type", choices = character(0), server = TRUE, selected = character(0))
      if ("ProjectionDate" %in% names(df)) {
        parsed_proj <- parse_projection_date_dateonly(df[["ProjectionDate"]]) |> as.Date()
        clean_proj  <- parsed_proj[!is.na(parsed_proj) & parsed_proj >= as.Date("2000-01-01") & parsed_proj <= as.Date("2100-12-31")]
        dropdown_choices <- if (length(clean_proj)) format(sort(unique(clean_proj)), "%d-%m-%Y") else character(0)
        preferred <- c("31-05-2025", "31-05-25")
        sel_pd <- (intersect(preferred, dropdown_choices))[1]; if (is.na(sel_pd) || length(sel_pd) == 0) sel_pd <- character(0)
        updateSelectizeInput(session, "projection_date", choices = dropdown_choices, server = TRUE, selected = sel_pd)
      } else updateSelectizeInput(session, "projection_date", choices = character(0), server = TRUE, selected = character(0))

      # Step 3: Generating preview (90%)
      incProgress(0.2, detail = "Generating preview table...")
      # Preview table
      output$tbl_preview <- renderDT({
        dfp <- uploaded_df(); req(!is.null(dfp))
        total_records <- nrow(dfp)
        if ("ProjectionDate" %in% names(dfp)) {
          cleaned <- parse_projection_date_dateonly(dfp[["ProjectionDate"]])
          dfp[["ProjectionDate"]] <- ifelse(!is.na(cleaned) &
                                              cleaned >= as.Date("2000-01-01") &
                                              cleaned <= as.Date("2100-12-31"),
                                            format(cleaned, "%d-%m-%Y"), NA_character_)
        }
        if ("Actual" %in% names(dfp))   dfp[["Actual"]]   <- to_float(dfp[["Actual"]])
        if ("Expected" %in% names(dfp)) dfp[["Expected"]] <- to_float(dfp[["Expected"]])
        # Calculate A - E and insert after Expected column
        if (all(c("Actual", "Expected") %in% names(dfp))) {
          dfp[["A - E"]] <- dfp[["Actual"]] - dfp[["Expected"]]
          # Reorder to place A - E right after Expected
          exp_idx <- which(names(dfp) == "Expected")
          col_order <- c(names(dfp)[1:exp_idx], "A - E", names(dfp)[(exp_idx + 1):(ncol(dfp) - 1)])
          dfp <- dfp[, col_order, drop = FALSE]
        }
        # Show full dataset with server-side processing for large data
        info_text <- sprintf("Showing _START_ to _END_ of %s records",
                             format(total_records, big.mark = ","))
        dt <- DT::datatable(dfp,
                            options  = list(
                              pageLength = 25,
                              scrollX = FALSE,   # Disable DT scroll - let CSS handle overflow
                              paging = TRUE,
                              fixedHeader = TRUE,
                              autoWidth = FALSE, # Disable auto-width - CSS 1% trick handles column sizing
                              language = list(info = info_text,
                                              infoFiltered = "(filtered from _MAX_ total records)")
                            ),
                            extensions = c("FixedHeader"),
                            rownames = FALSE, escape = FALSE)
        num_cols_fmt <- intersect(c("Actual","Expected","A - E"), names(dfp))
        if (length(num_cols_fmt)) {
          dt <- DT::formatCurrency(dt, columns = num_cols_fmt, currency = "", interval = 3, mark = ",", digits = 0)
          dt <- DT::formatStyle(dt, columns = num_cols_fmt, color = DT::styleInterval(c(-1e-12, 0), c("red","black","black")))
        }
        dt
      }, server = TRUE)  # Server-side processing for large datasets

      # Populate chart controls from RAW
      .populate_chart_controls_from_raw()

      # Step 4: Complete (100%)
      incProgress(0.1, detail = "Upload complete!")
    })

    # Show success notification
    showNotification(sprintf("File uploaded: %s rows, %s columns", format(nrow(df), big.mark = ","), ncol(df)), type = "message", duration = 3)
  })
  
  observeEvent(input$exclude_products, {
    # intentionally do nothing; let the user’s selection persist
  }, ignoreInit = TRUE)
  
  # >>> BEGIN PATCH E: POST-RUN CONTROL POPULATION (optional) <<<
  observeEvent(results_obj(), {
    ok <- .populate_chart_controls_from_paid_ave()
    if (!ok) {
      .populate_chart_controls_from_raw()
      showNotification(
        "No rows in Paid AvE after filters; Chart Controls populated from the uploaded file.",
        type = "warning", duration = 6
      )
    }
  }, ignoreInit = TRUE)
  # >>> END PATCH E <<<

}  # end register_upload_server
