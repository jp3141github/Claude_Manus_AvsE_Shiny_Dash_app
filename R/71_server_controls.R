# R/71_server_controls.R — Server control population and updates

register_controls_server <- function(input, output, session, uploaded_df, results_obj) {

  # Peril choices depend on Product (respect exclusions)
  observeEvent(input$dyn_prod, {
    res <- results_obj()
    pvt <- if (!is.null(res)) res[[SHEET_NAMES$paid_ave]] %||% res[["Paid AvE"]] else NULL
    df_src <- if (!is.null(pvt) && nrow(pvt) > 0) pvt else uploaded_df()
    req(!is.null(df_src), nrow(df_src) > 0)
    exc <- input$exclude_products %||% character(0)
    if (length(exc)) df_src <- df_src %>% dplyr::filter(!(Product %in% exc))
    perils <- if (identical(input$dyn_prod, "ALL")) {
      perils <- as.character(df_src$Peril)
    } else {
      perils <- as.character(df_src$Peril[df_src$Product == input$dyn_prod])
    }
    perils <- sorted_levels_az(setdiff(perils, c("", "TOTAL", "0", "0.0")))
    updateSelectInput(session, "dyn_peril", choices = c("ALL", perils), selected = "ALL")
  })

  # Assistant hooks (optional)
  if (ENABLE_ASSISTANT) {
    observe({ session$sendCustomMessage("injectKeys", list()) })
    observeEvent(input$assist_open, { showModal(assistant_modal) })
    observeEvent(input$assist_run,  { session$sendCustomMessage("triggerDownload", list(id = "run_analysis")) }, ignoreInit = TRUE)
    observeEvent(input$assist_clear,{
      updateSelectizeInput(session, "model_type", selected = character(0))
      updateSelectizeInput(session, "projection_date", selected = character(0))
      showNotification("Selections cleared.", type = "message", duration = 3)
    }, ignoreInit = TRUE)
    observeEvent(input$assist_zip,  { session$sendCustomMessage("triggerDownload", list(id = "download_zip")) },  ignoreInit = TRUE)
    observeEvent(input$assist_xlsx, { session$sendCustomMessage("triggerDownload", list(id = "download_excel")) }, ignoreInit = TRUE)
  }
}
