#!/usr/bin/env Rscript
# app.R — main entry: set working dir (locally), load modules, return shinyApp(ui, server)

suppressPackageStartupMessages({
  library(shiny)
})

# -------- Working directory (local dev only) --------
# Use the directory where app.R is located
# Try multiple methods to find the app directory
app_dir <- NULL

# Method 1: Try to get from the script path via commandArgs
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("--file=", args, value = TRUE)
if (length(file_arg) > 0) {
 app_dir <- dirname(normalizePath(sub("--file=", "", file_arg[1]), mustWork = FALSE))
}

# Method 2: If sourced, try sys.frame
if (is.null(app_dir) || app_dir == "." || !dir.exists(file.path(app_dir, "R"))) {
  tryCatch({
    ofile <- sys.frame(1)$ofile
    if (!is.null(ofile) && nzchar(ofile)) {
      app_dir <- dirname(normalizePath(ofile, mustWork = FALSE))
    }
  }, error = function(e) NULL)
}

# Method 3: If shiny::runApp was called with a path, the working directory should already be correct
if (is.null(app_dir) || !dir.exists(file.path(app_dir, "R"))) {
  # Check if current working directory has the expected structure
  if (file.exists("global.R") && dir.exists("R")) {
    app_dir <- getwd()
  }
}

# Method 4: Fallback - use current working directory
if (is.null(app_dir)) {
  app_dir <- getwd()
}

cat("== setwd/app_dir test ==\n")
print(app_dir); print(dir.exists(app_dir))

cat("\n== BEFORE setwd ==\n")
print(getwd()); print(list.files())

# Only change directory if we found a valid app directory with the R folder
if (dir.exists(app_dir) && dir.exists(file.path(app_dir, "R"))) {
  setwd(app_dir)
} else if (file.exists("global.R")) {
  # Already in the right directory, don't change
  message("Already in app directory")
} else {
  message("app_dir not found; staying in current working directory")
}

cat("\n== AFTER setwd ==\n")
print(getwd()); print(list.files()); if (dir.exists("R")) print(list.files("R"))

# -------- Options & debug --------
options(ave.debug = TRUE)
options(stringsAsFactors = FALSE)

# -------- Source global and verify required symbols --------
# Source into .GlobalEnv as you requested so that diagnostics find symbols there.
source("global.R", local = .GlobalEnv)

req <- c(
  "SHEET_NAMES","EXPECTED_COLUMNS",".force_char_ids",".force_text_ids_all",
  "coerce_types","levels_product_gt_last","levels_peril_total_last",
  "ts_year_cols","build_all_tables","build_total_summary","write_excel"
)

ok <- vapply(req, function(nm) exists(nm, envir = .GlobalEnv, inherits = TRUE), logical(1))

cat("\n== Required symbols present? ==\n")
print(setNames(ok, req))
if (!all(ok)) stop("Missing: ", paste(names(ok)[!ok], collapse = ", "))

# -------- Load UI and server --------
# ui.R must define `ui_bundle` (your chosen UI object name)
# server.R must define `server`
source("ui.R",     local = .GlobalEnv)
source("server.R", local = .GlobalEnv)

if (!exists("ui_bundle", inherits = TRUE)) {
  stop("ui_bundle not found after sourcing ui.R (did ui.R create `ui_bundle`?)")
}
if (!exists("server", inherits = TRUE)) {
  stop("server not found after sourcing server.R (did server.R create `server`?)")
}

cat("\n== App object ready (returning shinyApp; do NOT call runApp() here) ==\n")

# -------- Return the app object (RStudio Run App will call runApp() for you) --------
shinyApp(ui = ui_bundle, server = server)
