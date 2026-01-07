# R/01_palettes.R — Provides helper functions for generating consistent color and style palettes for charts

gg_line_colours     <- function() c("Actual" = COL_ACTUAL, "Expected" = COL_EXPECTED)
gg_line_types       <- function() c("Actual" = "solid",    "Expected" = "dotted")
gg_line_colours_cum <- function() c("Actual (agg)" = COL_ACTUAL, "Expected (agg)" = COL_EXPECTED)
gg_line_types_cum   <- function() c("Actual (agg)" = "solid",    "Expected (agg)" = "dotted")

hex_safe <- function(x, fallback) {
  x <- as.character(x)[1]
  if (!is.na(x) && grepl("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", x)) x else fallback
}
