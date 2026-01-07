#' @keywords internal
"_PACKAGE"

#' ShinyDashAE: Shiny Dashboard for Actual vs Expected Analysis
#'
#' @description
#' An interactive Shiny dashboard for analyzing Actual vs Expected insurance data.
#' Provides comprehensive visualization tools including heatmaps, line charts,
#' waterfall charts, and variance analysis. Supports data upload, filtering,
#' and export to Excel and ZIP formats.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{launch_dashboard}}: Launch the Shiny dashboard
#'   \item \code{\link{run_ave_dashboard}}: Alias for launch_dashboard
#' }
#'
#' @section Getting Started:
#' To launch the dashboard, simply run:
#' \preformatted{
#' library(ShinyDashAE)
#' launch_dashboard()
#' }
#'
#' @section Features:
#' \itemize{
#'   \item Interactive data upload (CSV/Excel)
#'   \item Multiple visualization types (heatmaps, lines, waterfalls, etc.)
#'   \item Product and peril filtering
#'   \item Excel and ZIP export capabilities
#'   \item Keyboard shortcuts for common actions
#'   \item Configurable via YAML configuration file
#' }
#'
#' @docType package
#' @name ShinyDashAE-package
NULL
