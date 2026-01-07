# R/00_constants.R — Defines global constants, such as sheet names, color codes, and feature flags.

# SHEET names + legacy aliases
SHEET_NAMES <- list(
  assessment           = "Assessment & Compliance Sheet",
  instructions         = "Instructions",
  warnings             = "Warnings",
  total_summary        = "Total Summary",
  class_summary        = "Class Summary",
  class_peril_summary  = "Class Peril Summary",
  paid_ave             = "Paid A v E",
  incurred_ave         = "Incurred A v E",
  paid_a               = "Paid A",
  paid_e               = "Paid E",
  incurred_a           = "Incurred A",
  incurred_e           = "Incurred E",
  raw                  = "A v E MRG Actuals Expecteds"
)

SHEET_RENAME_MAP <- c(
  "Paid AvE"               = "Paid A v E",
  "Incurred AvE"           = "Incurred A v E",
  "AvEMRGActualsExpecteds" = "A v E MRG Actuals Expecteds"
)

# ===== Year window rules (used by all pivot/Total Summary builders) =====
# These are fallback values - actual values come from config.yaml via R/05_config.R
# Only set if not already defined by config
if (!exists("YEAR_MIN_DEFAULT")) YEAR_MIN_DEFAULT <- 2010L
if (!exists("YEAR_MAX_DEFAULT")) YEAR_MAX_DEFAULT <- as.integer(format(Sys.Date(), "%Y"))
if (!exists("YEAR_FORCE_INCLUDE")) YEAR_FORCE_INCLUDE <- c(2023L, 2024L, 2025L)

# If TRUE, display *all* years from YEAR_MIN_DEFAULT..YEAR_MAX_DEFAULT.
# If FALSE, display only the years present in data (still union YEAR_FORCE_INCLUDE).
YEAR_ALWAYS_FULL_RANGE <- FALSE

# Brand colours (fallback - actual values come from config.yaml)
if (!exists("COL_ACTUAL")) COL_ACTUAL <- "#1565C0"
if (!exists("COL_EXPECTED")) COL_EXPECTED <- "#EF6C00"
if (!exists("COL_HEAT_POS")) COL_HEAT_POS <- "#D32F2F"
if (!exists("COL_HEAT_NEG")) COL_HEAT_NEG <- "#2E7D32"
if (!exists("COL_GOOD_AE")) COL_GOOD_AE <- "#99FF99"
if (!exists("COL_BAD_AE")) COL_BAD_AE <- "#FFCC66"

LINE_COLOURS      <- c("Actual" = COL_ACTUAL, "Expected" = COL_EXPECTED)
LINE_TYPES        <- c("Actual" = "solid",    "Expected" = "dotted")
LINE_COLOURS_CUM  <- c("Actual (agg)" = COL_ACTUAL, "Expected (agg)" = COL_EXPECTED)
LINE_TYPES_CUM    <- c("Actual (agg)" = "solid",    "Expected (agg)" = "dotted")

# Performance thresholds (fallback - actual values come from config.yaml)
if (!exists("RAW_MAX_ROWS_IN_RESULTS")) RAW_MAX_ROWS_IN_RESULTS <- 50000L
if (!exists("RAW_FAST_SCROLLER_ROWS")) RAW_FAST_SCROLLER_ROWS <- 30000L

# Feature flags (fallback - actual values come from config.yaml)
if (!exists("IN_BROWSER")) IN_BROWSER <- FALSE
if (!exists("GENERATE_STATIC_PNGS")) GENERATE_STATIC_PNGS <- FALSE
if (!exists("ENABLE_ASSISTANT")) ENABLE_ASSISTANT <- TRUE
