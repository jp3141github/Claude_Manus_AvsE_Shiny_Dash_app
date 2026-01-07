# R/13_utils_sort_levels.R — stable level helpers (NA-safe, case-insensitive)

# Keep only meaningful labels; trim; drop empties/zero-like; sort A→Z
sorted_levels_az <- function(x) {
  y <- as.character(x)
  y <- trimws(y)
  # drop empties and common zero/placeholder artefacts
  drop <- c("", "0", "0.0")
  y <- y[!(is.na(y) | y %in% drop)]
  sort(unique(y))
}

# PERIL levels with TOTAL last (case/space-insensitive)
levels_peril_total_last <- function(perils_chr) {
  p <- as.character(perils_chr)
  p_trim <- trimws(p)
  p_up   <- toupper(p_trim)
  
  core <- sorted_levels_az(p_trim[p_up != "TOTAL"])
  if (any(p_up == "TOTAL", na.rm = TRUE)) c(core, "TOTAL") else core
}

# PRODUCT/Class levels with "Grand Total" and "Check" last (case-insensitive)
levels_product_gt_last <- function(products_chr) {
  p <- as.character(products_chr)
  p_trim <- trimws(p)
  
  # normalise for comparison
  p_low <- tolower(p_trim)
  
  core <- sorted_levels_az(p_trim[!(p_low %in% c("grand total","check","0","0.0",""))])
  
  out <- core
  if (any(p_low == "grand total", na.rm = TRUE)) out <- c(out, "Grand Total")
  if (any(p_low == "check",       na.rm = TRUE)) out <- c(out, "Check")
  unique(out)
}

# Alias used by some builders for class ordering
safe_levels_class <- function(x) levels_product_gt_last(x)

# Segment Group ordering (optional helper): NIG, Non NIG (others A→Z after)
levels_segment_group <- function(x) {
  lab <- sorted_levels_az(x)
  # prefer canonical labels first
  ordered <- c("NIG", "Non NIG", setdiff(lab, c("NIG","Non NIG")))
  unique(ordered)
}
