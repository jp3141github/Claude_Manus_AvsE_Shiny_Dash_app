# R/05_config.R — Configuration loader using yaml

# Load configuration from config.yaml
# Falls back to hard-coded defaults if config file doesn't exist

.load_config <- function(config_file = "config.yaml") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    warning("yaml package not installed. Using hard-coded defaults. Install with: install.packages('yaml')")
    return(.default_config())
  }

  if (!file.exists(config_file)) {
    message("[config] config.yaml not found, using defaults")
    return(.default_config())
  }

  tryCatch({
    cfg <- yaml::read_yaml(config_file)
    message("[config] Loaded: ", config_file)
    cfg
  }, error = function(e) {
    warning("[config] Failed to parse config.yaml: ", e$message, ". Using defaults.")
    .default_config()
  })
}

# Hard-coded defaults (fallback)
.default_config <- function() {
  list(
    app = list(
      debug = TRUE,
      upload_max_mb = 25
    ),
    years = list(
      min_default = 2010L,
      min_absolute = 1980L,
      max_default = NULL,
      force_include = c(2023L, 2024L, 2025L)
    ),
    dates = list(
      projection_min = "2000-01-01",
      projection_max = "2100-12-31"
    ),
    performance = list(
      raw_max_rows = 50000L,
      raw_fast_threshold = 30000L,
      page_length_normal = 100L,
      page_length_fast = 50L,
      page_length_options = c(25L, 50L, 100L, 200L, 500L, 1000L),
      excel_width_sample_rows = 1000L
    ),
    colors = list(
      actual = "#1565C0",
      expected = "#EF6C00",
      heat_positive = "#D32F2F",
      heat_negative = "#2E7D32",
      good_ae = "#99FF99",
      bad_ae = "#FFCC66",
      excel_grey = "#EEEEEE",
      excel_yellow = "#FFF59D",
      excel_green = "#C8E6C9",
      excel_orange = "#FFE0B2",
      excel_header_text = "#FFFFFF",
      paid_ave = "#67B8FF",
      incurred_ave = "#7B2CBF"
    ),
    thresholds = list(
      ae_good = -2.5,
      ae_bad = 2.5,
      zero_tolerance = 1e-12
    ),
    chart = list(
      bar_width = 0.45,
      ae_alpha = 0.35
    ),
    ui = list(
      table_min_height = "600px",
      table_max_height = "2000px",
      spinner_bottom = "16px",
      spinner_right = "16px"
    ),
    timing = list(
      js_observer_delay = 500L,
      datatable_search_delay = 400L
    ),
    defaults = list(
      model_type = "Proxy",
      preferred_dates = c("31-05-2025", "31-05-25"),
      file_accept = c(".csv", ".xlsx", ".xls"),
      segment_group = "All",
      event_type = "Non-Event"
    ),
    features = list(
      enable_assistant = TRUE,
      generate_static_pngs = FALSE,
      in_browser = FALSE
    )
  )
}

# Helper to safely get nested config values
.get_config <- function(cfg, ..., default = NULL) {
  keys <- list(...)
  val <- cfg
  for (key in keys) {
    if (is.list(val) && key %in% names(val)) {
      val <- val[[key]]
    } else {
      return(default)
    }
  }
  val
}

# Load config once at startup
if (!exists("CFG", envir = .GlobalEnv)) {
  CFG <- .load_config()
}

# Export commonly used values as constants for backward compatibility
# These maintain the same variable names as before

# Years
YEAR_MIN_DEFAULT <- .get_config(CFG, "years", "min_default", default = 2010L)
YEAR_MIN_ABSOLUTE <- .get_config(CFG, "years", "min_absolute", default = 1980L)
YEAR_MAX_DEFAULT <- .get_config(CFG, "years", "max_default", default = as.integer(format(Sys.Date(), "%Y")))
if (is.null(YEAR_MAX_DEFAULT)) YEAR_MAX_DEFAULT <- as.integer(format(Sys.Date(), "%Y"))
YEAR_FORCE_INCLUDE <- .get_config(CFG, "years", "force_include", default = c(2023L, 2024L, 2025L))

# Colors
COL_ACTUAL <- .get_config(CFG, "colors", "actual", default = "#1565C0")
COL_EXPECTED <- .get_config(CFG, "colors", "expected", default = "#EF6C00")
COL_HEAT_POS <- .get_config(CFG, "colors", "heat_positive", default = "#D32F2F")
COL_HEAT_NEG <- .get_config(CFG, "colors", "heat_negative", default = "#2E7D32")
COL_GOOD_AE <- .get_config(CFG, "colors", "good_ae", default = "#99FF99")
COL_BAD_AE <- .get_config(CFG, "colors", "bad_ae", default = "#FFCC66")

# Excel colors
COL_EXCEL_GREY <- .get_config(CFG, "colors", "excel_grey", default = "#EEEEEE")
COL_EXCEL_YELLOW <- .get_config(CFG, "colors", "excel_yellow", default = "#FFF59D")
COL_EXCEL_GREEN <- .get_config(CFG, "colors", "excel_green", default = "#C8E6C9")
COL_EXCEL_ORANGE <- .get_config(CFG, "colors", "excel_orange", default = "#FFE0B2")
COL_EXCEL_HEADER_TEXT <- .get_config(CFG, "colors", "excel_header_text", default = "#FFFFFF")

# Chart colors
COL_PAID_AVE <- .get_config(CFG, "colors", "paid_ave", default = "#67B8FF")
COL_INCURRED_AVE <- .get_config(CFG, "colors", "incurred_ave", default = "#7B2CBF")

# Performance
RAW_MAX_ROWS_IN_RESULTS <- .get_config(CFG, "performance", "raw_max_rows", default = 50000L)
RAW_FAST_SCROLLER_ROWS <- .get_config(CFG, "performance", "raw_fast_threshold", default = 30000L)
PAGE_LENGTH_NORMAL <- .get_config(CFG, "performance", "page_length_normal", default = 100L)
PAGE_LENGTH_FAST <- .get_config(CFG, "performance", "page_length_fast", default = 50L)
PAGE_LENGTH_OPTIONS <- .get_config(CFG, "performance", "page_length_options", default = c(25L, 50L, 100L, 200L, 500L, 1000L))
EXCEL_WIDTH_SAMPLE_ROWS <- .get_config(CFG, "performance", "excel_width_sample_rows", default = 1000L)

# Thresholds
AE_THRESHOLD_GOOD <- .get_config(CFG, "thresholds", "ae_good", default = -2.5)
AE_THRESHOLD_BAD <- .get_config(CFG, "thresholds", "ae_bad", default = 2.5)
ZERO_TOLERANCE <- .get_config(CFG, "thresholds", "zero_tolerance", default = 1e-12)

# Chart settings
CHART_BAR_WIDTH <- .get_config(CFG, "chart", "bar_width", default = 0.45)
CHART_AE_ALPHA <- .get_config(CFG, "chart", "ae_alpha", default = 0.35)

# Dates
PROJECTION_DATE_MIN <- as.Date(.get_config(CFG, "dates", "projection_min", default = "2000-01-01"))
PROJECTION_DATE_MAX <- as.Date(.get_config(CFG, "dates", "projection_max", default = "2100-12-31"))

# Features
ENABLE_ASSISTANT <- .get_config(CFG, "features", "enable_assistant", default = TRUE)
GENERATE_STATIC_PNGS <- .get_config(CFG, "features", "generate_static_pngs", default = FALSE)
IN_BROWSER <- .get_config(CFG, "features", "in_browser", default = FALSE)

# Defaults
DEFAULT_MODEL_TYPE <- .get_config(CFG, "defaults", "model_type", default = "Proxy")
PREFERRED_PROJECTION_DATES <- .get_config(CFG, "defaults", "preferred_dates", default = c("31-05-2025", "31-05-25"))
FILE_ACCEPT_TYPES <- .get_config(CFG, "defaults", "file_accept", default = c(".csv", ".xlsx", ".xls"))
DEFAULT_SEGMENT_GROUP <- .get_config(CFG, "defaults", "segment_group", default = "All")
DEFAULT_EVENT_TYPE <- .get_config(CFG, "defaults", "event_type", default = "Non-Event")

# Upload size limit for Shiny
UPLOAD_MAX_SIZE_BYTES <- .get_config(CFG, "app", "upload_max_mb", default = 25) * 1024^2

if (isTRUE(.get_config(CFG, "app", "debug", default = TRUE))) {
  message("[config] Configuration loaded successfully")
  message("[config] Debug mode: ON")
}
