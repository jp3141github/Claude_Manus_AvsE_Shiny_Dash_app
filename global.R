# global.R - environment, packages, options, and modular loader

# --- Temp/cache hardening (Windows-friendly) ---
.local_tmp <- file.path(path.expand("~"), "AppData", "Local", "Temp")
if (!dir.exists(.local_tmp)) dir.create(.local_tmp, recursive = TRUE, showWarnings = FALSE)
Sys.setenv(TMPDIR = .local_tmp, TEMP = .local_tmp, TMP = .local_tmp)

# --- Packages ---
suppressPackageStartupMessages({
  library(shiny); library(bslib); library(DT)
  library(readr); library(readxl)
  library(dplyr); library(tidyr); library(stringr)
  library(lubridate); library(purrr); library(rlang)
  library(fs); library(glue)
  library(ggplot2); library(openxlsx); library(zip); library(scales)
  library(plotly); library(tibble)
})

# --- Kill the native R Graphics window for the whole Shiny session -----------
# Any accidental base/ggplot draw will go to a throwaway PNG file instead of
# opening the Windows/Mac graphics device. Plotly/ggplotly in Shiny are unaffected.
options(device.ask.default = FALSE)
.silent_file_device <- function(...) {
  fn <- tempfile("shiny_offscreen_", fileext = ".png")
  grDevices::png(filename = fn, width = 800, height = 600, res = 96)
}
options(device = .silent_file_device)

# --- Load configuration first (before other modules) ---
if (file.exists("R/05_config.R")) {
  sys.source("R/05_config.R", envir = .GlobalEnv)
} else {
  message("[global] R/05_config.R not found, using hard-coded defaults in R/00_constants.R")
}

# --- Options ---
options(stringsAsFactors = FALSE)
# Use config value if available, fallback to 25MB
if (exists("UPLOAD_MAX_SIZE_BYTES")) {
  options(shiny.maxRequestSize = UPLOAD_MAX_SIZE_BYTES)
} else {
  options(shiny.maxRequestSize = 25 * 1024 ^ 2)
}
# Use config value if available
if (exists("CFG") && is.list(CFG) && "app" %in% names(CFG) && "debug" %in% names(CFG$app)) {
  options(ave.debug = CFG$app$debug)
} else {
  options(ave.debug = TRUE)
}

# --- Source helper: write into THIS file's env (not a child env) ---
global_env <- environment()
source_if <- function(path, verbose = isTRUE(getOption("ave.debug", FALSE))) {
  if (file.exists(path)) {
    if (verbose) message("[global] source: ", path)
    sys.source(path, envir = .GlobalEnv)
    TRUE
  } else {
    warning(sprintf("[global] missing module: %s", path), call. = FALSE, immediate. = TRUE)
    FALSE
  }
}

# --- Module load order ---
if (!dir.exists("R")) dir.create("R", showWarnings = FALSE, recursive = TRUE)
module_chain <- c(
  "R/00_constants.R","R/01_palettes.R","R/02_expected_columns.R",
  "R/03a_css_core.R","R/03b_css_dt.R","R/03c_css_preview.R","R/03d_js_core.R","R/03e_js_dt_adv.R","R/03z_assets_bind.R",
  "R/10_utils_core.R","R/11_utils_ids.R","R/12_utils_types.R","R/13_utils_sort_levels.R",
  "R/14_utils_years.R","R/15_utils_numeric.R","R/16_utils_join_bind.R","R/17_utils_filters.R",
  "R/20_builders_core.R","R/21_builders_amounts.R","R/22_builders_percent.R","R/23_builders_total.R",
  "R/24_builders_pivots.R","R/30_heatmap_core.R","R/31_charts_lines.R","R/32_charts_heatmaps.R",
  "R/33_charts_waterfall.R","R/34_charts_variance.R","R/35_charts_png_pack.R",
  "R/40_excel_writer.R","R/41_zip_io.R","R/50_orchestration.R",
  "R/60_ui_components.R"
)
loaded <- vapply(module_chain, source_if, logical(1))

# --- Scrub BOM'd names before we check symbols ---
.fix_bom_names <- function(env = global_env) {
  ns <- ls(envir = env, all.names = TRUE)
  bad <- ns[startsWith(ns, "\ufeff")]
  for (old in bad) {
    new <- sub("^\ufeff", "", old, useBytes = TRUE)
    assign(new, get(old, envir = env), envir = env)
    rm(list = old, envir = env)
    message("[global] fixed BOM name: ", old, " -> ", new)
  }
}
.fix_bom_names()

# Debug summary
if (isTRUE(getOption("ave.debug", FALSE))) {
  message(sprintf("[global] modules loaded: %d/%d", sum(loaded), length(module_chain)))
}

# --- Symbol existence checks (against global_env) ---
symbol_file_map <- list(
  SHEET_NAMES              = "R/00_constants.R",
  EXPECTED_COLUMNS         = "R/02_expected_columns.R",
  `.force_char_ids`        = "R/11_utils_ids.R",
  `.force_text_ids_all`    = "R/11_utils_ids.R",
  coerce_types             = "R/12_utils_types.R",
  levels_product_gt_last   = "R/13_utils_sort_levels.R",
  levels_peril_total_last  = "R/13_utils_sort_levels.R",
  ts_year_cols             = "R/14_utils_years.R",
  build_total_summary      = "R/23_builders_total.R",
  build_all_tables         = "R/50_orchestration.R",
  write_excel              = "R/40_excel_writer.R"
)

required_symbols <- names(symbol_file_map)
present <- vapply(required_symbols, function(nm) exists(nm, envir = global_env, inherits = FALSE), logical(1))

if (isTRUE(getOption("ave.debug", FALSE))) {
  message("[global] Symbol -> file check")
  for (nm in required_symbols) {
    message(sprintf("  %-24s  exists=%-5s  <- %s",
                    nm, if (present[[nm]]) "TRUE" else "FALSE", symbol_file_map[[nm]]))
  }
}

# Scope recovery: if anything is missing, force re-source to .GlobalEnv, scrub again, re-check
missing_symbols <- required_symbols[!present]
if (length(missing_symbols)) {
  message("[global] Attempting scope recovery for missing symbols ...")
  for (f in unique(unlist(symbol_file_map[missing_symbols], use.names = FALSE))) {
    if (file.exists(f)) { message("  re-source -> ", f); sys.source(f, envir = .GlobalEnv) }
  }
  .fix_bom_names(.GlobalEnv)
  present <- vapply(required_symbols, function(nm) exists(nm, envir = global_env, inherits = TRUE), logical(1))
  missing_symbols <- required_symbols[!present]
}

if (length(missing_symbols)) {
  message("[global] Still missing after recovery:")
  for (nm in missing_symbols) message("  - ", nm, "  (expected in ", symbol_file_map[[nm]], ")")
  # Show a small sample of what's actually defined
  message("[global] sample in global_env: ", paste(utils::head(ls(envir = global_env)), collapse = ", "))
  message("[global] sample in .GlobalEnv: ", paste(utils::head(ls(envir = .GlobalEnv)), collapse = ", "))
  stop("global.R: missing required objects after sourcing modules.", call. = FALSE)
}

message("[global] All required symbols loaded successfully")
