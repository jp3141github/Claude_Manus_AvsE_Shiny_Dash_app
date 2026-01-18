# R/75_server_checks.R — Server validation and control population

register_checks_server <- function(input, output, session, uploaded_df, results_obj) {

  # ----- Controls population (respects exclusions) -----
  # Define helper functions in parent environment using <<- so they're accessible to other modules
  .get_safe_levels_from_df <<- function(df, excluded = character(0)) {
    if (is.null(df) || !nrow(df)) return(list(prods = character(0), perils = character(0)))
    df <- df %>%
      dplyr::mutate(Product = as.character(Product %||% ""),
                    Peril   = as.character(Peril   %||% "")) %>%
      dplyr::filter(Product != "")
    if (length(excluded)) df <- df %>% dplyr::filter(!(Product %in% excluded))

    prods  <- sorted_levels_az(setdiff(df$Product, c("", "Grand Total", "Check", "0", "0.0")))
    perils <- sorted_levels_az(setdiff(df$Peril,   c("", "TOTAL",      "0", "0.0")))
    list(prods = prods, perils = perils)
  }

  .populate_chart_controls_from_raw <<- function() {
    d <- uploaded_df(); if (is.null(d) || !nrow(d)) return(FALSE)
    exc <- input$exclude_products %||% character(0)
    lv  <- .get_safe_levels_from_df(d, excluded = exc)
    updateSelectInput(session, "dyn_prod",  choices = c("ALL", lv$prods),  selected = "ALL")
    updateSelectInput(session, "dyn_peril", choices = c("ALL", lv$perils), selected = "ALL")
    updateCheckboxGroupInput(session, "exclude_products", choices = lv$prods,
                             selected = intersect(exc, lv$prods))
    TRUE
  }

  .populate_chart_controls_from_paid_ave <<- function() {
    res <- results_obj(); if (is.null(res)) return(FALSE)
    pvt <- res[[SHEET_NAMES$paid_ave]] %||% res[["Paid AvE"]]
    if (is.null(pvt) || !nrow(pvt)) return(FALSE)

    prods  <- sorted_levels_az(setdiff(as.character(pvt$Product), c("", "Grand Total", "Check", "0", "0.0")))
    perils <- sorted_levels_az(setdiff(as.character(pvt$Peril),   c("", "TOTAL",      "0", "0.0")))

    updateSelectInput(session, "dyn_prod",  choices = c("ALL", prods),  selected = "ALL")
    updateSelectInput(session, "dyn_peril", choices = c("ALL", perils), selected = "ALL")

    exc <- input$exclude_products %||% character(0)
    updateCheckboxGroupInput(session, "exclude_products", choices = prods,
                             selected = intersect(exc, prods))
    TRUE
  }
  
  # ---- Header block (unchanged behaviour) ----
  fmt_commas <- function(n) format(n, big.mark = ",", scientific = FALSE, trim = TRUE)
  
  current_state <- reactive({
    df   <- uploaded_df()
    nrec <- if (!is.null(df) && nrow(df) > 0) fmt_commas(nrow(df)) else "0"
    fname <- tryCatch({ fn <- input$csv_file$name; if (is.null(fn) || !nzchar(fn)) "—" else fn }, error = function(e) "—")
    list(
      mode        = if (IN_BROWSER) "Browser (WebAssembly)" else "Desktop",
      file        = fname,
      records     = nrec,
      event_label = { v <- input$event_type; if (is.null(v) || !nzchar(as.character(v))) "Non-Event" else as.character(v) },
      model_type  = { v <- input$model_type; if (is.null(v) || !nzchar(as.character(v))) "—" else as.character(v) },
      projection_date = {
        v <- input$projection_date
        if (inherits(v, "Date")) format(v, "%Y/%m/%d")
        else if (!is.null(v) && nzchar(as.character(v))) {
          vv <- suppressWarnings(as.Date(v, tryFormats = c("%Y/%m/%d","%Y-%m-%d","%d-%m-%Y","%d/%m/%Y")))
          if (!is.na(vv)) format(vv, "%Y/%m/%d") else as.character(v)
        } else "—"
      }
    )
  })
  
  output$full_header_block <- renderUI({
    s <- current_state()
    div(class = "ave-header",
        div(class = "meta",
            strong("Mode:"),   span(paste0(" ", s$mode)),   span(class="sep", " | "),
            strong("File:"),   span(paste0(" ", s$file)),   span(class="sep", " | "),
            strong("Records:"),span(paste0(" ", s$records))),
        div(class = "meta",
            strong("Event / Non-Event:"), span(paste0(" ", s$event_label)),  span(class="sep", " | "),
            strong("Model Type:"),        span(paste0(" ", s$model_type)),   span(class="sep", " | "),
            strong("Projection Date:"),   span(paste0(" ", s$projection_date)))
    )
  })

}  # end register_checks_server
