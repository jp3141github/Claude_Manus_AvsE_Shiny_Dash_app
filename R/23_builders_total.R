# R/23_builders_total.R — Total summary builder (Paid/Incurred by year)

build_total_summary <- function(df, years) {
  as_num_len <- function(x, n) { v <- suppressWarnings(as.numeric(x)); if (length(v) != n) v <- if (length(v)==1) rep(v, n) else rep(0, n); v[is.na(v)] <- 0; v }
  make_block <- function(basis, years) {
    d <- df %>% dplyr::filter(Measure == basis)
    a_tbl <- d %>% group_by(`Accident Year`) %>% summarise(Actual = sum(Actual, na.rm = TRUE), .groups = "drop") %>%
      right_join(tibble(`Accident Year` = years), by = "Accident Year") %>% arrange(`Accident Year`) %>% mutate(Actual = coalesce(Actual, 0.0))
    e_tbl <- d %>% group_by(`Accident Year`) %>% summarise(Expected = sum(Expected, na.rm = TRUE), .groups = "drop") %>%
      right_join(tibble(`Accident Year` = years), by = "Accident Year") %>% arrange(`Accident Year`) %>% mutate(Expected = coalesce(Expected, 0.0))
    n <- length(years)
    actual_m   <- as_num_len(a_tbl$Actual,   n) / 1e6
    expected_m <- as_num_len(e_tbl$Expected, n) / 1e6
    ave_m      <- as_num_len(a_tbl$Actual - e_tbl$Expected, n) / 1e6
    den <- e_tbl$Expected
    pct_vals <- pmax(pmin(ifelse(den == 0, NA_real_, (a_tbl$Actual - e_tbl$Expected) / den), 9.999), -9.999)
    years_chr <- as.character(years)
    r_actual   <- data.frame(`A vs E` = "Actual",   t(actual_m),   check.names = FALSE); names(r_actual)[-1] <- years_chr; r_actual$`Grand Total` <- sum(actual_m, na.rm = TRUE)
    r_expected <- data.frame(`A vs E` = "Expected", t(expected_m), check.names = FALSE); names(r_expected)[-1] <- years_chr; r_expected$`Grand Total` <- sum(expected_m, na.rm = TRUE)
    r_ae       <- data.frame(`A vs E` = "A-E",      t(ave_m),      check.names = FALSE); names(r_ae)[-1] <- years_chr; r_ae$`Grand Total` <- sum(ave_m, na.rm = TRUE)
    r_pct      <- data.frame(`A vs E` = "%",        t(pct_vals),    check.names = FALSE); names(r_pct)[-1] <- years_chr
    gt_ratio <- if (sum(e_tbl$Expected, na.rm = TRUE) == 0) NA_real_ else (sum(a_tbl$Actual - e_tbl$Expected, na.rm = TRUE) / sum(e_tbl$Expected, na.rm = TRUE))
    r_pct$`Grand Total` <- pmax(pmin(gt_ratio, 9.999), -9.999)
    r_check <- data.frame(`A vs E` = "Check", t(rep(0, n)), check.names = FALSE); names(r_check)[-1] <- years_chr; r_check$`Grand Total` <- 0
    block <- dplyr::bind_rows(r_actual, r_expected, r_ae, r_pct, r_check)
    block$Basis <- basis; block <- dplyr::relocate(block, Basis, .before = `A vs E`)
    block[years_chr] <- lapply(block[years_chr], function(x) suppressWarnings(as.numeric(x)))
    block[["Grand Total"]] <- suppressWarnings(as.numeric(block[["Grand Total"]]))
    block
  }
  paid_blk     <- make_block("Paid", years)
  incurred_blk <- make_block("Incurred", years)
  final <- dplyr::bind_rows(paid_blk, incurred_blk)
  num_cols <- c(as.character(years), "Grand Total")
  final[num_cols] <- lapply(final[num_cols], function(x) suppressWarnings(as.numeric(x)))
  final
}
