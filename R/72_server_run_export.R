# R/72_server_run_export.R — Server run analysis and export handlers

register_run_export_server <- function(input, output, session, uploaded_df, results_obj,
                                       charts_pngs, zip_blob, excel_blob,
                                       .show_busy, .hide_busy) {

  # ---- Run analysis (HYBRID: exclusions + first script flow) ----
  observeEvent(input$run_analysis, {
    .show_busy(); on.exit(.hide_busy(), add = TRUE)

    # Wrap entire process in progress indicator
    withProgress(message = 'Running analysis', value = 0, {

      # Step 1: Validation (10%)
      incProgress(0.1, detail = "Validating inputs...")
      df <- uploaded_df(); if (is.null(df) || !nrow(df)) { showNotification("Upload a CSV first.", type = "error"); return() }
      mt <- input$model_type; pd_str <- input$projection_date; ev <- input$event_type %||% "Non-Event"
      if (is.null(mt) || !nzchar(mt) || is.null(pd_str) || !nzchar(pd_str)) { showNotification("Select Model Type and Projection Date.", type = "error"); return() }
      proj_dt <- suppressWarnings(lubridate::dmy(pd_str))
      if (is.na(proj_dt) || proj_dt < as.Date("2000-01-01") || proj_dt > as.Date("2100-12-31")) {
        showNotification(glue::glue("Projection Date not parseable or out of range: {pd_str}"), type = "error"); return()
      }

      # Step 2: Building tables (10% -> 50%)
      incProgress(0.1, detail = sprintf("Building tables (%s rows)...", format(nrow(df), big.mark = ",")))
      tables <- tryCatch({
        build_all_tables(df,
                         model_type      = mt,
                         projection_date = proj_dt,
                         event_type      = ev,
                         excluded_products = input$exclude_products %||% character(0))
      }, error = function(e) {
        # make sure something readable shows up
        msg <- tryCatch(conditionMessage(e), error = function(...) "")
        if (!nzchar(msg)) msg <- paste("(", paste(class(e), collapse = "/"), ")", sep = "")
        showNotification(glue::glue("Build failed: {msg}"), type = "error", duration = 10)

        # also print a traceback to the console for diagnosis
        try({
          message("[ERROR] build_all_tables failed: ", msg)
          # capture and print the last traceback (if any)
          tb <- utils::capture.output(traceback(x = NULL, max.lines = 4))
          if (length(tb)) message("[TRACEBACK]\n", paste(tb, collapse = "\n"))
        }, silent = TRUE)
        NULL
      })

      # >>> ADD THIS GUARD <<<
      if (is.null(tables)) {
        .hide_busy()
        return()
      }

      incProgress(0.3, detail = "Tables built successfully")

      results_obj(tables)                      # <<< lets Results/Charts render
      updateTabsetPanel(session, "tabs_main", selected = "Results")   # optional: jump to Results

      charts_pngs(list())  # interactive only

      # Step 3: Creating ZIP bundle (70%)
      incProgress(0.2, detail = "Creating ZIP bundle...")
      tmpdir <- tempfile("avezip")
      fs::dir_create(tmpdir)

      safe_name <- function(x) gsub("[^A-Za-z0-9 _.-]", "_", x)

      # quick debug to see any non-data-frame entries
      bad_keys <- names(tables)[!vapply(tables, function(x) inherits(x, "data.frame"), logical(1))]
      if (length(bad_keys)) {
        msg <- sprintf("Skipping non-tabular outputs in ZIP: %s", paste(bad_keys, collapse = ", "))
        message("[WARN] ", msg)
        showNotification(msg, type = "warning", duration = 6)
      }

      for (sh in names(tables)) {
        obj <- tables[[sh]]
        # skip NULL or non-tabular
        if (is.null(obj) || !inherits(obj, "data.frame")) next
        readr::write_csv(obj,
                         file = fs::path(tmpdir, paste0(safe_name(sh), ".csv")),
                         na = ""
        )
      }

      zfile <- tempfile(fileext = ".zip")
      zip::zipr(
        zipfile = zfile,
        files   = fs::dir_ls(tmpdir, recurse = TRUE),
        root    = tmpdir
      )
      zip_blob(readBin(zfile, "raw", file.size(zfile)))

      # Step 4: Creating Excel (90%)
      incProgress(0.2, detail = "Generating Excel workbook...")
      # Excel (desktop only)
      if (!IN_BROWSER) {
        ok <- tryCatch({
          outdir <- input$output_location
          xlsx_path <- if (!is.null(outdir) && nzchar(outdir)) { fs::dir_create(outdir, recurse = TRUE); fs::path(outdir, paste0("analysis_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx")) }
          else tempfile(pattern = "analysis_results_", fileext = ".xlsx")
          write_excel(tables, xlsx_path,
                      uploaded_df = df,
                      filters = list(
                        model_type = mt,
                        projection_date = format(proj_dt, "%d-%m-%Y"),
                        event_type = ev,
                        excluded_products = input$exclude_products %||% character(0)
                      ))
          excel_blob(readBin(xlsx_path, "raw", file.size(xlsx_path)))
          if (!is.null(outdir) && nzchar(outdir)) showNotification(glue::glue("Excel saved to: {xlsx_path}"), type = "message", duration = 5)
          else showNotification("Excel generated to temp; use 'Download Excel' to save.", type="warning", duration=6)
          TRUE
        }, error = function(e) { excel_blob(NULL); showNotification(glue::glue("Excel not saved: {e$message}"), type = "warning"); FALSE })
        invisible(ok)
      } else excel_blob(NULL)

      # Step 5: Complete (100%)
      incProgress(0.1, detail = "Complete!")
    })

    showNotification("Analysis complete.", type = "message", duration = 5)
  })

  # Export (Python-style)
  observeEvent(input$export_excel_now, {
    .show_busy(); on.exit(.hide_busy(), add = TRUE)

    withProgress(message = 'Exporting to Excel', value = 0, {
      # Step 1: Validation (10%)
      incProgress(0.1, detail = "Validating inputs...")
      df <- uploaded_df(); if (is.null(df) || !nrow(df)) { showNotification("Upload a CSV/XLSX first.", type="error"); return() }
      mt <- input$model_type; pdstr <- input$projection_date; ev <- input$event_type %||% "Non-Event"
      if (is.null(mt) || !nzchar(mt) || is.null(pdstr) || !nzchar(pdstr)) { showNotification("Select Model Type and Projection Date.", type="error"); return() }
      proj_dt <- suppressWarnings(lubridate::dmy(pdstr)); if (is.na(proj_dt)) { showNotification("Projection Date not parseable.", type="error"); return() }

      # Step 2: Building tables (30%)
      incProgress(0.2, detail = "Building tables...")
      tabs <- tryCatch({
        build_all_tables(df,
                         model_type      = mt,
                         projection_date = proj_dt,
                         event_type      = ev,
                         excluded_products = input$exclude_products %||% character(0))
      }, error = function(e) { showNotification(paste("Build failed:", e$message), type="error"); NULL })
      if (is.null(tabs)) return()
      results_obj(tabs)

      # Step 3: Writing Excel file (60%)
      incProgress(0.3, detail = "Writing Excel file...")
      base_dir   <- { if (!is.null(input$output_location) && nzchar(input$output_location)) { fs::dir_create(input$output_location, recurse = TRUE); input$output_location } else { dl <- fs::path_home("Downloads"); if (fs::dir_exists(dl)) dl else tempdir() } }
      xlsx_path  <- fs::path(base_dir, sprintf("AvE_Report_%s.xlsx", format(Sys.time(), "%Y-%m-%d_%H%M")))
      charts_dir <- paste0(fs::path_ext_remove(xlsx_path), "_charts")

      ok_x <- tryCatch({
        write_excel(tabs, xlsx_path,
                    uploaded_df = df,
                    filters = list(
                      model_type = mt,
                      projection_date = pdstr,
                      event_type = ev,
                      excluded_products = input$exclude_products %||% character(0)
                    ))
        TRUE
      }, error = function(e) { showNotification(paste("Excel export failed:", e$message), type="error"); FALSE })
      if (!ok_x) return()

      # Step 4: Generating charts (if enabled) (80%)
      if (GENERATE_STATIC_PNGS) {
        incProgress(0.2, detail = "Generating static charts...")
        try({ make_full_chart_pack(tabs, charts_base_dir = charts_dir) }, silent = TRUE)
      } else {
        incProgress(0.2, detail = "Finalizing export...")
      }

      excel_blob(readBin(xlsx_path, "raw", file.size(xlsx_path)))

      # Step 5: Complete (100%)
      incProgress(0.2, detail = "Complete!")
    })

    showNotification(glue::glue("✓ Exported: {xlsx_path}\n✓ Charts: {charts_dir}"), type="message", duration=7)
  })

  # Downloads
  output$download_zip <- downloadHandler(
    filename = function() paste0("results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip"),
    content  = function(file) { blob <- zip_blob(); if (is.null(blob)) writeBin(raw(), file) else writeBin(blob, file) }
  )
  output$download_excel <- downloadHandler(
    filename = function() paste0("results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx"),
    content  = function(file) {
      blob <- excel_blob()
      if (is.null(blob)) {
        wb <- openxlsx::createWorkbook(); openxlsx::addWorksheet(wb, "Info")
        openxlsx::writeData(wb, "Info", data.frame(Info = "Excel available on desktop run only."))
        openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
      } else writeBin(blob, file)
    }
  )
}
