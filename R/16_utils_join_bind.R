# R/16_utils_join_bind.R — Provides robust wrapper functions for joining and binding data frames safely.

full_join_ids <- function(x, y, by, ...) full_join(.force_char_ids(x), .force_char_ids(y), by = by, ...)
bind_rows_ids <- function(...) { dots <- lapply(list(...), .force_char_ids); dplyr::bind_rows(dots) }
br_rows <- function(xlist) { xlist <- Filter(function(x) is.data.frame(x) && ncol(x) > 0, xlist); if (!length(xlist)) return(tibble()); dplyr::bind_rows(xlist) }
.dedupe_names <- function(df) { if (is.null(df) || !ncol(df)) return(df); names(df) <- make.unique(names(df), sep = " "); df }
