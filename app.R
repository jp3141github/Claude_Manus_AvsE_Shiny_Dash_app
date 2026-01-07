#!/usr/bin/env Rscript
# app.R — main entry: set working dir (locally), load modules, return shinyApp(ui, server)

suppressPackageStartupMessages({
  library(shiny)
})

# -------- Working directory (local dev only) --------
# If you're deploying (e.g., shinyapps.io/Shiny Server), either remove this
# or let it silently skip when the path doesn't exist.
app_dir <- "C:/Users/QLCY/Downloads/ActualVersusExpected_RStudio/CODE"
cat("== setwd/app_dir test ==\n")
print(app_dir); print(dir.exists(app_dir))

cat("\n== BEFORE setwd ==\n")
print(getwd()); print(list.files())

if (dir.exists(app_dir)) {
  setwd(app_dir)
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
source("ui.R",     local = TRUE)
source("server.R", local = TRUE)

if (!exists("ui_bundle", inherits = TRUE)) {
  stop("ui_bundle not found after sourcing ui.R (did ui.R create `ui_bundle`?)")
}
if (!exists("server", inherits = TRUE)) {
  stop("server not found after sourcing server.R (did server.R create `server`?)")
}

cat("\n== App object ready (returning shinyApp; do NOT call runApp() here) ==\n")

# -------- Return the app object (RStudio Run App will call runApp() for you) --------
shinyApp(ui = ui_bundle, server = server)
