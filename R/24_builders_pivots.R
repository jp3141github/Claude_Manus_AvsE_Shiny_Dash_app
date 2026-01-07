# R/24_builders_pivots.R — Pivot builder functions for Product×Peril×Year tables

pivot_product_peril_by_year <- function(df, value_col, years) {
  if (length(years) == 0) return(tibble(Product=character(), Peril=character(), `Grand Total`=numeric()))
  df <- df %>% mutate(`Accident Year` = suppressWarnings(as.integer(`Accident Year`)))
  pvt <- df %>%
    group_by(Product, Peril, `Accident Year`) %>%
    summarise(value = sum(.data[[value_col]], na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = `Accident Year`, values_from = value, values_fill = 0.0)
  for (yr in years) if (!as.character(yr) %in% names(pvt)) pvt[[as.character(yr)]] <- 0.0
  pvt <- pvt %>% select(Product, Peril, all_of(as.character(years)))
  if (nrow(pvt) == 0) return(tibble(Product=character(), Peril=character(), !!!set_names(rep(list(numeric()), length(years)), as.character(years)), `Grand Total`=numeric()))
  pvt <- pvt %>% mutate(`Grand Total` = rowSums(across(all_of(as.character(years)))))
  class_totals <- pvt %>% group_by(Product) %>% summarise(across(all_of(as.character(years)), ~ sum(.x, na.rm = TRUE)), .groups = "drop") %>%
    mutate(Peril = "TOTAL") %>% relocate(Peril, .after = Product) %>% mutate(`Grand Total` = rowSums(across(all_of(as.character(years)))))
  out <- list()
  # A→Z products
  prods_ord <- levels_product_gt_last(pvt$Product)
  for (prod in prods_ord) {
    p_sub <- pvt %>% filter(Product == prod)
    # A→Z perils with TOTAL last
    peril_levels <- levels_peril_total_last(p_sub$Peril)
    perils_only <- p_sub %>%
      filter(toupper(trimws(Peril)) != "TOTAL") %>%
      mutate(Peril = factor(Peril, levels = peril_levels)) %>%
      arrange(Peril)
    total_row   <- class_totals %>% filter(Product == prod)
    out[[length(out) + 1]] <- perils_only
    out[[length(out) + 1]] <- total_row
  }
  br_rows(out)
}

py_cy_split <- function(df, value_col) {
  g1 <- df %>% group_by(Product, Peril, `Current or Prior`) %>% summarise(val = sum(.data[[value_col]], na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = `Current or Prior`, values_from = val, values_fill = 0.0) %>% sanitize_ids()
  g2 <- df %>% group_by(Product, `Current or Prior`) %>% summarise(val = sum(.data[[value_col]], na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = `Current or Prior`, values_from = val, values_fill = 0.0) %>% mutate(Peril = "TOTAL") %>% sanitize_ids()
  for (nm in c("PY","CY")) { if (!(nm %in% names(g1))) g1[[nm]] <- 0.0; if (!(nm %in% names(g2))) g2[[nm]] <- 0.0 }
  list(g_peril = g1 %>% ungroup() %>% select(Product, Peril, PY, CY),
       g_prod  = g2 %>% ungroup() %>% select(Product, Peril, PY, CY))
}
three_block_ave_table <- function(g_peril, g_prod) {
  prod  <- g_prod  %>% select(Product, Peril, PY, CY) %>% sanitize_ids()
  peril <- g_peril %>% select(Product, Peril, PY, CY) %>% sanitize_ids()
  bind_rows(prod, peril) %>%
    mutate(
      Product = factor(Product, levels = levels_product_gt_last(Product)),
      Peril   = factor(Peril,   levels = levels_peril_total_last(Peril))
    ) %>%
    arrange(Product, Peril)
}
append_grand_total_row_pvt <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(df)
  num_cols <- c(names(df)[vapply(names(df), function(c) !is.na(suppressWarnings(as.integer(c))), logical(1))], if ("Grand Total" %in% names(df)) "Grand Total")
  totals_only <- df %>% filter(toupper(trimws(Peril)) == "TOTAL")
  gt_vals <- purrr::map_dbl(num_cols, ~ sum(totals_only[[.x]], na.rm = TRUE)); names(gt_vals) <- num_cols
  gt <- c(list(Product = "Grand Total", Peril = ""), as.list(gt_vals))
  bind_rows(df, as_tibble(gt))
}

build_paid_ave     <- function(df, years) { append_grand_total_row_pvt(pivot_product_peril_by_year(df %>% filter(Measure=="Paid"),     "A - E",    years)) }
build_incurred_ave <- function(df, years) { append_grand_total_row_pvt(pivot_product_peril_by_year(df %>% filter(Measure=="Incurred"), "A - E",    years)) }
build_paid_a       <- function(df, years) { append_grand_total_row_pvt(pivot_product_peril_by_year(df %>% filter(Measure=="Paid"),     "Actual",   years)) }
build_paid_e       <- function(df, years) { append_grand_total_row_pvt(pivot_product_peril_by_year(df %>% filter(Measure=="Paid"),     "Expected", years)) }
build_incurred_a   <- function(df, years) { append_grand_total_row_pvt(pivot_product_peril_by_year(df %>% filter(Measure=="Incurred"), "Actual",   years)) }
build_incurred_e   <- function(df, years) { append_grand_total_row_pvt(pivot_product_peril_by_year(df %>% filter(Measure=="Incurred"), "Expected", years)) }
