#' Launch the Actual vs Expected Dashboard
#'
#' @description
#' Launches the Shiny dashboard for Actual vs Expected analysis.
#' This function starts the interactive web application in your default browser.
#'
#' @param launch.browser Logical, whether to launch the app in a browser.
#'   Default is TRUE. Set to FALSE to run in RStudio Viewer pane.
#' @param port Integer, the port to run the application on. If NULL (default),
#'   Shiny will automatically select an available port.
#' @param host Character, the host to run the application on. Default is "127.0.0.1".
#' @param ... Additional arguments passed to \code{\link[shiny]{runApp}}
#'
#' @return Starts a Shiny app (doesn't return a value)
#'
#' @examples
#' \dontrun{
#' # Launch the dashboard
#' launch_dashboard()
#'
#' # Launch on a specific port
#' launch_dashboard(port = 8080)
#'
#' # Launch without opening browser (RStudio Viewer)
#' launch_dashboard(launch.browser = FALSE)
#' }
#'
#' @export
#' @importFrom shiny runApp
launch_dashboard <- function(launch.browser = TRUE, port = NULL, host = "127.0.0.1", ...) {
  # Get the app directory from the package installation
  app_dir <- system.file("shinyapp", package = "ShinyDashAE")

  if (app_dir == "") {
    stop("Could not find Shiny app directory. Is the ShinyDashAE package installed correctly?")
  }

  message("Starting Actual vs Expected Dashboard...")
  message("App directory: ", app_dir)

  # Run the Shiny app
  shiny::runApp(
    appDir = app_dir,
    launch.browser = launch.browser,
    port = port,
    host = host,
    ...
  )
}

#' Run the Actual vs Expected Dashboard
#'
#' @description
#' Alias for \code{\link{launch_dashboard}}. Launches the Shiny dashboard
#' for Actual vs Expected analysis.
#'
#' @param ... Arguments passed to \code{\link{launch_dashboard}}
#'
#' @return Starts a Shiny app (doesn't return a value)
#'
#' @examples
#' \dontrun{
#' # Launch the dashboard
#' run_ave_dashboard()
#' }
#'
#' @export
run_ave_dashboard <- function(...) {
  launch_dashboard(...)
}
