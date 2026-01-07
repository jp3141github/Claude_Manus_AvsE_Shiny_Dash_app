# R/31_charts_core.R — Core chart helper functions (time-series utilities)

# ---------- Time-series utilities ----------
ts_year_cols <- function(df) {
  years <- c()
  for (c in names(df)) {
    y <- suppressWarnings(as.integer(c))
    if (!is.na(y) && y >= 1900 && y <= 2100) years <- c(years, y)
  }
  sort(unique(years))
}

ts_slice <- function(df, basis, kind) {
  years <- ts_year_cols(df)
  row <- df %>% dplyr::filter(Basis == basis, `A vs E` == kind)
  if (nrow(row) == 0) return(stats::setNames(rep(0, length(years)), years))
  as.numeric(row[1, as.character(years), drop = TRUE])
}

ts_fmt <- function(x, dp = 2) {
  tryCatch(formatC(x, format = "f", digits = dp, big.mark = ","),
           error = function(e) as.character(x))
}

ts_ensure_dir <- function(out_dir) {
  if (is.null(out_dir) || is.na(out_dir) || out_dir == "") return(NULL)
  fs::dir_create(out_dir, recurse = TRUE)
  out_dir
}

# ---------- PNG saver helper ----------
ggsave_raw <- function(plot, filename, out_dir = NULL, width = 10, height = 5, dpi = 144) {
  tf <- tempfile(fileext = ".png")
  ggplot2::ggsave(tf, plot = plot, width = width, height = height, dpi = dpi,
                  units = "in", bg = "white")
  blob <- readBin(tf, what = "raw", n = file.size(tf))
  if (!is.null(out_dir)) {
    fs::dir_create(out_dir, recurse = TRUE)
    fs::file_copy(tf, fs::path(out_dir, paste0(filename, ".png")), overwrite = TRUE)
  }
  unlink(tf)
  list(name = filename, blob = blob)
}

