# R/14_utils_years.R — year helpers

fmt_year_labels <- function(yrs) {
  yrs <- as.integer(yrs)
  if (length(yrs) > 18) sprintf("%02d", yrs %% 100) else as.character(yrs)
}

year_axis <- function(years) {
  years <- sort(unique(as.integer(years)))
  list(breaks = years, labels = fmt_year_labels(years))
}

ts_year_cols <- function(df, min_year = 1980, max_year = as.integer(format(Sys.Date(), "%Y")) + 1L) {
  if (is.null(df) || !nrow(df)) return(integer(0))
  nm <- names(df)
  # detect headers that contain a 4-digit year; prefer exact match if possible
  yr <- suppressWarnings(as.integer(gsub("^.*?(\\d{4}).*$", "\\1", nm)))
  keep <- !is.na(yr) & yr >= min_year & yr <= max_year
  yrs <- unique(yr[keep])
  sort(yrs)
}

.full_years <- function(df, year_col = "accidentyear", min_year = NULL, max_year = NULL) {
  y <- suppressWarnings(as.integer(as.character(df[[year_col]])))
  y <- y[is.finite(y)]
  if (!length(y)) return(integer(0))
  lo <- if (is.null(min_year)) min(y) else min_year
  hi <- if (is.null(max_year)) max(y) else max_year
  seq.int(lo, hi)
}

.year_labels <- function(years) fmt_year_labels(years)
