# R/22_builders_class_peril.R — Class peril summary builder functions (amounts and percent)

build_class_peril_summary_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_peril_summary(d)
    if (!nrow(tbl)) return(tbl)
    tbl$`Segment (Group)` <- grp
    tbl
  }
  d_nig <- df %>% dplyr::filter(Segment == "NIG")
  d_non <- df %>% dplyr::filter(Segment != "NIG" | is.na(Segment))
  
  out <- dplyr::bind_rows(make(d_nig, "NIG"), make(d_non, "Non NIG")) %>%
    .force_text_ids_all() %>%
    ensure_id_cols() %>%
    dplyr::mutate(
      Peril         = as.character(Peril),
      `Class/Peril` = as.character(`Class/Peril`)
    ) %>%
    dplyr::relocate(Peril, `Segment (Group)`, `Class/Peril`) %>%
    .force_text_ids_all %>%
    dplyr::mutate(Peril = trimws(Peril), `Class/Peril` = trimws(`Class/Peril`)) %>%
    dplyr::filter(Peril == "" | toupper(Peril) == "TOTAL" | grepl("[A-Za-z]", Peril))
  
  out <- out %>%
    {
      .$`Class/Peril` <- factor(as.character(.$`Class/Peril`), levels = safe_levels_class(.$`Class/Peril`))
      .
    }
  
  cls_levels <- levels(out$`Class/Peril`)
  rebuild <- lapply(cls_levels, function(cls) {
    dsub <- dplyr::filter(out, `Class/Peril` == cls)
    plv  <- levels_peril_total_last(dsub$Peril)
    dsub %>%
      dplyr::mutate(Peril = factor(Peril, levels = plv)) %>%
      dplyr::arrange(Peril)
  })
  out <- dplyr::bind_rows(rebuild)
  
  out$Peril <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  
  # >>> duplicate-name guard
  if (anyDuplicated(names(out))) {
    keep <- !duplicated(names(out))
    out <- out[, keep, drop = FALSE]
  }
  out
}

# ---------- Class Peril Summary pct — with Segment (Group)
build_class_peril_summary_pct_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_peril_summary_pct(d)
    if (!nrow(tbl)) return(tbl)
    tbl$`Segment (Group)` <- grp
    tbl
  }
  d_nig <- df %>% dplyr::filter(Segment == "NIG")
  d_non <- df %>% dplyr::filter(Segment != "NIG" | is.na(Segment))
  
  out <- dplyr::bind_rows(make(d_nig, "NIG"), make(d_non, "Non NIG")) %>%
    .force_text_ids_all %>% ensure_id_cols() %>%
    dplyr::mutate(
      Peril         = trimws(as.character(Peril)),
      `Class/Peril` = trimws(as.character(`Class/Peril`))
    ) %>%
    # keep TOTAL and blanks (for GT), plus anything that isn't a pure integer artefact
    dplyr::filter(Peril == "" | toupper(Peril) == "TOTAL" | !grepl("^[0-9]+$", Peril)) %>%
    dplyr::relocate(Peril, `Segment (Group)`, `Class/Peril`)
  
  out <- out %>%
    {
      .$`Class/Peril` <- factor(as.character(.$`Class/Peril`), levels = safe_levels_class(.$`Class/Peril`))
      .
    }
  
  cls_levels <- levels(out$`Class/Peril`)
  rebuild <- lapply(cls_levels, function(cls) {
    dsub <- dplyr::filter(out, `Class/Peril` == cls)
    plv  <- levels_peril_total_last(dsub$Peril)
    dsub %>%
      dplyr::mutate(Peril = factor(Peril, levels = plv)) %>%
      dplyr::arrange(Peril)
  })
  out <- dplyr::bind_rows(rebuild)
  
  out$Peril <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  
  # >>> duplicate-name guard
  # end of build_class_peril_summary_pct_with_segment()
  out$Peril         <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  if (anyDuplicated(names(out))) { keep <- !duplicated(names(out)); out <- out[, keep, drop = FALSE] }
  out <- .ids_text_guard(out)     # <<< add
  
  out
  
}

build_class_peril_summary_pct <- function(df) {
  d_paid <- df %>% dplyr::filter(Measure == "Paid")
  d_inc  <- df %>% dplyr::filter(Measure == "Incurred")
  
  gp_paid_AE <- py_cy_split(d_paid, "A - E")
  gi_inc_AE  <- py_cy_split(d_inc,  "A - E")
  AE_paid <- three_block_ave_table(gp_paid_AE$g_peril, gp_paid_AE$g_prod) %>% dplyr::rename(PY_Paid = PY, CY_Paid = CY)
  AE_inc  <- three_block_ave_table(gi_inc_AE$g_peril,  gi_inc_AE$g_prod)  %>% dplyr::rename(PY_Incurred = PY, CY_Incurred = CY)
  AE <- full_join_ids(AE_paid, AE_inc, by = c("Product","Peril")) %>% na0_numeric()
  
  gp_paid_E <- py_cy_split(d_paid, "Expected")
  gi_inc_E  <- py_cy_split(d_inc,  "Expected")
  E_paid <- three_block_ave_table(gp_paid_E$g_peril, gp_paid_E$g_prod) %>% dplyr::rename(PY_Paid = PY, CY_Paid = CY)
  E_inc  <- three_block_ave_table(gi_inc_E$g_peril,  gi_inc_E$g_prod)  %>% dplyr::rename(PY_Incurred = PY, CY_Incurred = CY)
  E <- full_join_ids(E_paid, E_inc, by = c("Product","Peril")) %>% na0_numeric()
  
  M <- full_join_ids(AE, E, by = c("Product","Peril"), suffix = c("_AE","_E")) %>% na0_numeric() %>% dplyr::ungroup()
  if (!nrow(M)) {
    return(tibble(`Class/Peril`=character(), Peril=character(),
                  `PY Paid`=numeric(), `PY Incurred`=numeric(),
                  `CY Paid`=numeric(), `CY Incurred`=numeric(),
                  `Total Paid`=numeric(), `Total Incurred`=numeric()))
  }
  
  ensure_cols <- function(d, cols) {
    n <- nrow(d)
    for (nm in cols) {
      if (!(nm %in% names(d))) d[[nm]] <- rep(0, n) else {
        v <- suppressWarnings(as.numeric(d[[nm]]))
        if (length(v) != n) v <- rep(0, n)
        v[is.na(v)] <- 0
        d[[nm]] <- v
      }
    }
    d
  }
  needed <- c("PY_Paid_AE","CY_Paid_AE","PY_Incurred_AE","CY_Incurred_AE",
              "PY_Paid_E","CY_Paid_E","PY_Incurred_E","CY_Incurred_E")
  M <- ensure_cols(M, needed)
  
  div <- function(a, b) ifelse(b == 0, NA_real_, a / b)
  clamp <- function(v) pmax(pmin(v, 9.999), -9.999)
  
  for (side in c("Paid","Incurred")) {
    py_num <- M[[paste0("PY_", side, "_AE")]]; py_den <- M[[paste0("PY_", side, "_E")]]
    cy_num <- M[[paste0("CY_", side, "_AE")]]; cy_den <- M[[paste0("CY_", side, "_E")]]
    M[[paste0("PY_", side)]]    <- as.numeric(clamp(div(py_num, py_den)))
    M[[paste0("CY_", side)]]    <- as.numeric(clamp(div(cy_num, cy_den)))
    M[[paste0("Total_", side)]] <- as.numeric(clamp(div(py_num + cy_num, py_den + cy_den)))
  }
  
  base <- M %>%
    dplyr::select(Product, Peril, PY_Paid, PY_Incurred, CY_Paid, CY_Incurred, Total_Paid, Total_Incurred)
  
  if (!nrow(base)) {
    return(tibble(
      `Class/Peril` = character(), Peril = character(),
      `PY Paid` = numeric(), `PY Incurred` = numeric(),
      `CY Paid` = numeric(), `CY Incurred` = numeric(),
      `Total Paid` = numeric(), `Total Incurred` = numeric()
    ))
  }
  
  # Grand Total ratios (class-level, using Peril == TOTAL)
  AE_T <- AE %>% dplyr::filter(Peril == "TOTAL")
  E_T  <- E  %>% dplyr::filter(Peril == "TOTAL")
  rs <- function(num, den) if (den %in% c(0, 0.0)) NA_real_ else num / den
  
  grand <- tibble::tibble(
    Product = "Grand Total", Peril = "",
    PY_Paid        = clamp(rs(sum(AE_T$PY_Paid),        sum(E_T$PY_Paid))),
    PY_Incurred    = clamp(rs(sum(AE_T$PY_Incurred),    sum(E_T$PY_Incurred))),
    CY_Paid        = clamp(rs(sum(AE_T$CY_Paid),        sum(E_T$CY_Paid))),
    CY_Incurred    = clamp(rs(sum(AE_T$CY_Incurred),    sum(E_T$CY_Incurred))),
    Total_Paid     = clamp(rs(sum(AE_T$PY_Paid)     + sum(AE_T$CY_Paid),
                              sum(E_T$PY_Paid)      + sum(E_T$CY_Paid))),
    Total_Incurred = clamp(rs(sum(AE_T$PY_Incurred) + sum(AE_T$CY_Incurred),
                              sum(E_T$PY_Incurred)  + sum(E_T$CY_Incurred)))
  )
  
  # Drop any accidental pre-existing 'Class/Peril' column before renaming Product
  if ("Class/Peril" %in% names(base))  base[["Class/Peril"]]  <- NULL
  if ("Class/Peril" %in% names(grand)) grand[["Class/Peril"]] <- NULL
  
  out <- dplyr::bind_rows(base, grand) %>%
    dplyr::rename(
      `Class/Peril` = Product,
      `PY Paid` = PY_Paid, `PY Incurred` = PY_Incurred,
      `CY Paid` = CY_Paid, `CY Incurred` = CY_Incurred,
      `Total Paid` = Total_Paid, `Total Incurred` = Total_Incurred
    )
  
  # Order perils first then TOTAL per class; add Grand Total at end
  inner <- out %>% dplyr::filter(!`Class/Peril` %in% c("Grand Total"))
  order_perils_then_total <- function(dfin) {
    # A→Z classes (Class/Peril) with "Grand Total" last if present
    dfin <- dfin %>%
      mutate(`Class/Peril` = factor(`Class/Peril`, levels = levels_product_gt_last(`Class/Peril`)))
    outl <- list()
    for (cls in levels(dfin$`Class/Peril`)) {
      dsub <- dplyr::filter(dfin, `Class/Peril` == cls)
      peril_levels <- levels_peril_total_last(dsub$Peril)
      dsub <- dsub %>%
        mutate(Peril = factor(Peril, levels = peril_levels)) %>%
        arrange(Peril)
      outl[[length(outl)+1]] <- dsub
    }
    br_rows(outl)
  }
  inner <- order_perils_then_total(inner)
  tail  <- out %>% dplyr::filter(`Class/Peril` %in% c("Grand Total"))
  final <- bind_rows_ids(inner, tail)

  # IDs must be text (avoid numeric factor codes)
  final <- .force_text_ids_all(final)
  if ("Product" %in% names(final)) final$Product <- NULL
  
  final <- final %>%
    {
      .$`Class/Peril` <- factor(as.character(.$`Class/Peril`), levels = safe_levels_class(.$`Class/Peril`))
      .
    }
  
  cls_levels <- levels(final$`Class/Peril`)
  rebuild <- lapply(cls_levels, function(cls) {
    dsub <- dplyr::filter(final, `Class/Peril` == cls)
    plv  <- levels_peril_total_last(dsub$Peril)
    dsub %>%
      dplyr::mutate(Peril = factor(Peril, levels = plv)) %>%
      dplyr::arrange(Peril)
  })
  final <- dplyr::bind_rows(rebuild)
  
  # ... existing code above ...
  final$`Class/Peril` <- as.character(final$`Class/Peril`)
  final$Peril         <- as.character(final$Peril)
  
  # >>> add this guard
  if (anyDuplicated(names(final))) {
    keep <- !duplicated(names(final))
    final <- final[ , keep, drop = FALSE]
  }
  
  return(final)
}
# <<< END REPLACE 1 <<<

build_class_peril_summary <- function(df) {
  merged <- class_summary_core(df)
  
  # Ensure required numeric columns exist
  need <- c("PY_Paid","PY_Incurred","CY_Paid","CY_Incurred","Total_Paid","Total_Incurred")
  for (nm in need) if (!(nm %in% names(merged))) merged[[nm]] <- 0
  
  keep_cols <- c("Product","Peril", need)
  
  # Cast numerics; set factor levels via brace-block to avoid mutate/.data quirks
  out <- merged %>%
    dplyr::select(dplyr::all_of(keep_cols)) %>%
    dplyr::mutate(dplyr::across(-c(Product, Peril), ~ suppressWarnings(as.numeric(.)))) %>%
    {
      lv_prod <- levels_product_gt_last(.$Product)
      lv_per  <- levels_peril_total_last(.$Peril)
      .$Product <- factor(as.character(.$Product), levels = lv_prod)
      .$Peril   <- factor(as.character(.$Peril),   levels = lv_per)
      .
    } %>%
    dplyr::arrange(Product, Peril)
  
  # Drop rows that are all-zero across metrics
  metric_cols <- setdiff(names(out), c("Product","Peril"))
  out <- out[rowSums(abs(as.data.frame(out[metric_cols]))) != 0, , drop = FALSE]
  
  # Class totals (Peril == TOTAL) then Grand Total across classes
  class_totals <- out %>%
    dplyr::filter(toupper(trimws(Peril)) == "TOTAL") %>%
    dplyr::group_by(Product) %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(metric_cols), ~ sum(.x, na.rm = TRUE)), .groups = "drop")
  
  grand <- tibble::tibble(Product = "Grand Total", Peril = "")
  for (nm in metric_cols) grand[[nm]] <- sum(class_totals[[nm]], na.rm = TRUE)
  
  # Scale to £m
  out[metric_cols]   <- lapply(out[metric_cols],   function(x) as.numeric(x) / 1e6)
  grand[metric_cols] <- lapply(grand[metric_cols], function(x) as.numeric(x) / 1e6)
  
  final <- dplyr::bind_rows(out, grand) %>%
    dplyr::rename(`Class/Peril` = Product) %>%
    dplyr::relocate(Peril, .before = `Class/Peril`)
  
  # Return plain text IDs (consistent with other builders)
  final$Peril         <- as.character(final$Peril)
  final$`Class/Peril` <- as.character(final$`Class/Peril`)
  
  final
}
