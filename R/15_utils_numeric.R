# R/15_utils_numeric.R — numeric safety helpers + utilities (vectorised & debug-lite)

.num_dbg <- function(fmt, ...) { if (isTRUE(getOption("ave.debug", FALSE))) message(sprintf(fmt, ...)) }

# Vectorised safe divide: returns NA where den is 0 or NA; otherwise num/den
safe_divide <- function(num, den) {
  # Coerce to numeric vectors with sane recycling
  num <- suppressWarnings(as.numeric(num))
  den <- suppressWarnings(as.numeric(den))
  # Compute result and then mask invalid denominators
  out <- num / den
  mask <- is.na(den) | den == 0
  out[mask] <- NA_real_
  out
}

# Alias for clarity in percentage contexts (also vectorised)
safe_pct <- function(num, den) {
  safe_divide(num, den)
}

# Clamp vector of percentages (or ratios) to ±lim
clamp_pct <- function(x, lim = 9.999) {
  x <- suppressWarnings(as.numeric(x))
  pmax(pmin(x, lim), -lim)
}

is_true <- function(x) isTRUE(x)
cond_non_na <- function(x) !is.na(x) & x

na0_numeric <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  num_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  if (length(num_cols)) {
    df[num_cols] <- lapply(df[num_cols], function(x){ x[is.na(x)] <- 0; x })
  }
  df
}

.ensure_numeric_cols <- function(df, cols) {
  if (is.null(df) || !nrow(df)) return(df)
  for (nm in cols) {
    if (!(nm %in% names(df))) df[[nm]] <- NA_real_
    df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))
  }
  df
}

align_series <- function(s_years, s_vals, years) {
  if (!length(years)) return(numeric())
  if (!length(s_years)) return(rep(NA_real_, length(years)))
  m <- match(years, s_years)
  out <- rep(NA_real_, length(years))
  ok <- !is.na(m)
  out[ok] <- s_vals[m[ok]]
  out
}

# Scale numeric columns to millions by dividing by 1e6
# Preserves non-numeric columns (Product, Peril, etc.) unchanged
scale_millions <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)

  # Identify numeric columns
  num_cols <- names(df)[vapply(df, is.numeric, logical(1))]

  # Scale numeric columns to millions
  if (length(num_cols)) {
    df[num_cols] <- lapply(df[num_cols], function(x) {
      suppressWarnings(as.numeric(x)) / 1e6
    })
  }

  df
}
