# R/20_builders_core.R — Core helper functions for table builders

# Split data by Prior Year (PY) and Current Year (CY), returning aggregated values
py_cy_split <- function(df, value_col) {
  g1 <- df %>% group_by(Product, Peril, `Current or Prior`) %>% summarise(val = sum(.data[[value_col]], na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = `Current or Prior`, values_from = val, values_fill = 0.0) %>% sanitize_ids()
  g2 <- df %>% group_by(Product, `Current or Prior`) %>% summarise(val = sum(.data[[value_col]], na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = `Current or Prior`, values_from = val, values_fill = 0.0) %>% mutate(Peril = "TOTAL") %>% sanitize_ids()
  for (nm in c("PY","CY")) { if (!(nm %in% names(g1))) g1[[nm]] <- 0.0; if (!(nm %in% names(g2))) g2[[nm]] <- 0.0 }
  list(g_peril = g1 %>% ungroup() %>% select(Product, Peril, PY, CY),
       g_prod  = g2 %>% ungroup() %>% select(Product, Peril, PY, CY))
}

# Combine product-level and peril-level data into a single A v E table
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

# Append Grand Total row to a pivot table (sums TOTAL rows across products)
append_grand_total_row_pvt <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(df)
  num_cols <- c(names(df)[vapply(names(df), function(c) !is.na(suppressWarnings(as.integer(c))), logical(1))], if ("Grand Total" %in% names(df)) "Grand Total")
  totals_only <- df %>% filter(toupper(trimws(Peril)) == "TOTAL")
  gt_vals <- purrr::map_dbl(num_cols, ~ sum(totals_only[[.x]], na.rm = TRUE)); names(gt_vals) <- num_cols
  gt <- c(list(Product = "Grand Total", Peril = ""), as.list(gt_vals))
  bind_rows(df, as_tibble(gt))
}

# Core logic for building class summaries (used by both amounts and percent builders)
class_summary_core <- function(df) {
  d_paid <- df %>% filter(Measure == "Paid")
  d_inc  <- df %>% filter(Measure == "Incurred")
  gp_paid <- py_cy_split(d_paid, "A - E"); gi_inc <- py_cy_split(d_inc, "A - E")
  paid_tbl <- three_block_ave_table(gp_paid$g_peril, gp_paid$g_prod) %>% sanitize_ids()
  inc_tbl  <- three_block_ave_table(gi_inc$g_peril,  gi_inc$g_prod)  %>% sanitize_ids()
  merged <- full_join_ids(paid_tbl, inc_tbl, by = c("Product","Peril"), suffix = c("_Paid","_Incurred")) %>% sanitize_ids() %>% na0_numeric()
  num_fix <- c("PY_Paid","CY_Paid","PY_Incurred","CY_Incurred")
  for (nm in num_fix) if (!(nm %in% names(merged))) merged[[nm]] <- 0
  merged[num_fix] <- lapply(merged[num_fix], function(x) suppressWarnings(as.numeric(x)))
  needed <- c("PY_Paid","CY_Paid","PY_Incurred","CY_Incurred"); for (nm in needed) if (!nm %in% names(merged)) merged[[nm]] <- 0
  merged %>% mutate(Total_Paid = PY_Paid + CY_Paid, Total_Incurred = PY_Incurred + CY_Incurred)
}

# Ensure ID columns exist (avoids "Unknown or uninitialised column" errors)
ensure_id_cols <- function(df) {
  if (!"Peril" %in% names(df))         df$Peril <- ""
  if (!"Class/Peril" %in% names(df))   df$`Class/Peril` <- ""
  df
}

# Force all ID columns to text (Product, Peril, Class/Peril, Segment (Group))
.force_text_ids_all <- function(df) {
  for (nm in intersect(c("Product","Peril","Class/Peril","Segment (Group)"), names(df))) {
    df[[nm]] <- as.character(df[[nm]])
  }
  df
}

# ID text hard-guard (use at sheet boundaries to ensure no factor codes leak)
.ids_text_guard <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  for (nm in c("Peril","Class/Peril","Product","Segment (Group)")) {
    if (nm %in% names(df)) df[[nm]] <- as.character(df[[nm]])
  }
  df
}

# Safe levels for class names (A-Z with Grand Total last)
safe_levels_class <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x <- x[!(is.na(x) | x == "" | x == "0" | x == "0.0")]
  unique(levels_product_gt_last(x))
}
