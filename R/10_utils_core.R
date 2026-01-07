# R/10_utils_core.R — core helpers (debug, infix, names)

`%||%` <- function(a, b) {
  # If a is NULL or zero-length, return b.
  if (is.null(a) || length(a) == 0) return(b)

  # Vector-safe check for "empty-like" atomic vectors (e.g. c(NA, NA) or c("", "")).
  # This prevents "condition has length > 1" errors when the operator's
  # result is used in an if() statement.
  if (is.atomic(a)) {
    is_empty <- if (is.character(a)) {
      all(is.na(a) | !nzchar(a))
    } else {
      all(is.na(a))
    }
    if (is_empty) return(b)
  }

  a
}

scalar_or <- function(x, default) {
  # Use default if x is NULL or not a vector of length 1 (i.e., not a scalar).
  if (is.null(x) || length(x) != 1L) default else x
}

# Debug helpers (enabled when options(ave.debug = TRUE))
._dbg <- function(...) {
  if (isTRUE(getOption("ave.debug", FALSE))) {
    message(sprintf(...))
  }
}

dbg_rows <- function(tag, d) {
  if (!isTRUE(getOption("ave.debug", FALSE))) return(invisible(NULL))
  if (is.null(d) || !nrow(d)) {
    message(sprintf("[%-12s] rows=0", tag))
    return(invisible(NULL))
  }
  paid <- sum(d$Measure == "Paid", na.rm = TRUE)
  incd <- sum(d$Measure == "Incurred", na.rm = TRUE)
  yrs  <- suppressWarnings(as.integer(d[["Accident Year"]]))
  message(sprintf("[%-12s] rows=%s | Paid=%s | Incd=%s | AY=%s..%s",
                  tag, nrow(d), paid, incd,
                  suppressWarnings(min(yrs, na.rm = TRUE)),
                  suppressWarnings(max(yrs, na.rm = TRUE))))
  invisible(NULL)
}

is_raw_sheet_name <- function(x) {
  # Use the canonical raw sheet name from config, with a fallback.
  expected <- get0("SHEET_NAMES", ifnotfound = list())$raw %||% "A v E MRG Actuals Expecteds"
  # The "AvEMRGActualsExpecteds" variant is a common alternative without spaces.
  x %in% c(expected, "AvEMRGActualsExpecteds")
}
