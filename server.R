# server.R — orchestrates server chunks defined under R/

server <- function(input, output, session) {
  # App-wide reactives/blobs
  uploaded_df <- reactiveVal(NULL)
  results_obj <- reactiveVal(NULL)
  charts_pngs <- reactiveVal(list())
  zip_blob    <- reactiveVal(NULL)
  excel_blob  <- reactiveVal(NULL)

  # Busy overlay helpers
  .show_busy <- function() session$sendCustomMessage("toggleOverlay", list(show = TRUE))
  .hide_busy <- function() session$sendCustomMessage("toggleOverlay", list(show = FALSE))

  # Track when first Results table and first Chart actually render
  if (is.null(session$userData$paint)) session$userData$paint <- reactiveValues(results = FALSE, charts = FALSE)

  observe({
    if (isTRUE(session$userData$paint$results) && isTRUE(session$userData$paint$charts)) {
      .hide_busy()
    }
  })

  # Make RAW available to modules without duplicating in results_obj
  options(ave.raw_provider = uploaded_df)

  # Source server chunk files (they register observers/outputs)
  # These files must be sourced INSIDE the server function so they have
  # access to input, output, session, and the reactive values defined above.
  # Use local = environment() to define functions in the server function's environment
  for (f in c("R/70_server_upload.R",
              "R/71_server_controls.R",
              "R/72_server_run_export.R",
              "R/73_server_results.R",
              "R/74_server_charts.R",
              "R/75_server_checks.R")) {
    if (file.exists(f)) source(f, local = environment())
  }

  # Register chunked server logic (these functions come from the server_* files)
  # Use inherits = FALSE to check only the local environment where the functions were defined
  if (exists("register_checks_server", inherits = FALSE)) {
    register_checks_server(input, output, session, uploaded_df, results_obj)
  }
  if (exists("register_upload_server", inherits = FALSE)) {
    register_upload_server(input, output, session, uploaded_df)
  }
  if (exists("register_controls_server", inherits = FALSE)) {
    register_controls_server(input, output, session, uploaded_df, results_obj)
  }

  # Source additional server files needed for new features
  if (file.exists("R/76_server_validation.R")) source("R/76_server_validation.R", local = environment())
  if (file.exists("R/77_server_chart_downloads.R")) source("R/77_server_chart_downloads.R", local = environment())

  # Register chart downloads server first (provides chart_data reactive)
  chart_data <- NULL
  if (exists("register_chart_downloads_server", inherits = FALSE)) {
    chart_data <- register_chart_downloads_server(input, output, session, results_obj)
  }

  if (exists("register_results_server", inherits = FALSE)) {
    register_results_server(input, output, session, results_obj, uploaded_df)
  }
  if (exists("register_charts_server", inherits = FALSE)) {
    register_charts_server(input, output, session, results_obj, chart_data)
  }
  if (exists("register_run_export_server", inherits = FALSE)) {
    register_run_export_server(
      input, output, session,
      uploaded_df, results_obj, charts_pngs, zip_blob, excel_blob,
      .show_busy = .show_busy, .hide_busy = .hide_busy
    )
  }
  if (exists("register_validation_server", inherits = FALSE)) {
    register_validation_server(input, output, session, uploaded_df, results_obj)
  }
}
