# R/21_builders_class.R — Class summary builder functions (amounts and percent)

build_class_summary <- function(df) {
  merged <- class_summary_core(df)
  class_only <- merged %>% filter(Peril == "TOTAL") %>% select(Product, PY_Paid, PY_Incurred, CY_Paid, CY_Incurred, Total_Paid, Total_Incurred)
  metric_cols <- c("PY_Paid","PY_Incurred","CY_Paid","CY_Incurred","Total_Paid","Total_Incurred")
  class_only <- class_only %>% mutate(across(all_of(metric_cols), ~ as.numeric(ifelse(is.na(.x), 0, .x))))
  zero_mask <- rowSums(abs(class_only[metric_cols])) == 0; class_only <- class_only[!zero_mask, , drop = FALSE]
  gt <- tibble(Product="Grand Total", PY_Paid=sum(class_only$PY_Paid), PY_Incurred=sum(class_only$PY_Incurred),
               CY_Paid=sum(class_only$CY_Paid), CY_Incurred=sum(class_only$CY_Incurred),
               Total_Paid=sum(class_only$Total_Paid), Total_Incurred=sum(class_only$Total_Incurred))
  check <- tibble(Product="Check", PY_Paid=0, PY_Incurred=0, CY_Paid=0, CY_Incurred=0, Total_Paid=0, Total_Incurred=0)
  class_only <- bind_rows(class_only, gt, check)
  num_cols <- setdiff(names(class_only), "Product")
  class_only[num_cols] <- lapply(class_only[num_cols], function(x) as.numeric(x)/1e6)
  class_only %>% rename(`Class/Peril` = Product, `PY Paid`=PY_Paid, `PY Incurred`=PY_Incurred, `CY Paid`=CY_Paid, `CY Incurred`=CY_Incurred,
                        `Total Paid`=Total_Paid, `Total Incurred`=Total_Incurred) %>% mutate(Peril="TOTAL") %>%
    relocate(Peril, .before = `Class/Peril`)
}

build_class_summary_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_summary(d)
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
    # first 3 cols (front) without duplicating anything
    dplyr::relocate(Peril, `Segment (Group)`, `Class/Peril`) %>%
    # drop numeric-only peril artefacts
    .force_text_ids_all %>%
    dplyr::mutate(Peril = trimws(Peril), `Class/Peril` = trimws(`Class/Peril`)) %>%
    dplyr::filter(Peril == "" | toupper(Peril) == "TOTAL" | grepl("[A-Za-z]", Peril))

  # ordering: classes A→Z (Grand Total last), perils A→Z with TOTAL last per class
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
  
  # return plain text ids
  out$Peril <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  
  # >>> duplicate-name guard
  if (anyDuplicated(names(out))) {
    keep <- !duplicated(names(out))
    out <- out[, keep, drop = FALSE]
  }
  out
}

build_class_summary_pct_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_summary_pct(d)
    if (!nrow(tbl)) return(tbl[0, ])   # empty but typed
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
  
  # order for display (temporary factors), then return as character
  if (nrow(out)) {
    out$`Class/Peril` <- factor(out$`Class/Peril`, levels = safe_levels_class(out$`Class/Peril`))
    
    rebuilt <- lapply(levels(out$`Class/Peril`), function(cls) {
      dsub <- dplyr::filter(out, `Class/Peril` == cls)
      plv  <- levels_peril_total_last(dsub$Peril)
      dsub %>%
        dplyr::mutate(Peril = factor(Peril, levels = plv)) %>%
        dplyr::arrange(Peril)
    })
    out <- dplyr::bind_rows(rebuilt)
  }
  
  # FINAL: Excel-safe (no factors)
  # end of build_class_summary_pct_with_segment()
  out$Peril         <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  if (anyDuplicated(names(out))) out <- out[, !duplicated(names(out)), drop = FALSE]
  out <- .ids_text_guard(out)     # <<< add
  
  out
  
}

build_class_summary_pct <- function(df) {
  d_paid <- df %>% dplyr::filter(Measure == "Paid")
  d_inc  <- df %>% dplyr::filter(Measure == "Incurred")
  
  gp_paid_AE <- py_cy_split(d_paid, "A - E")
  gi_inc_AE  <- py_cy_split(d_inc,  "A - E")
  AE_paid <- three_block_ave_table(gp_paid_AE$g_peril, gp_paid_AE$g_prod) %>% 
    .force_char_ids %>% dplyr::rename(PY_Paid = PY, CY_Paid = CY)
  AE_inc  <- three_block_ave_table(gi_inc_AE$g_peril,  gi_inc_AE$g_prod) %>% 
    .force_char_ids %>% dplyr::rename(PY_Incurred = PY, CY_Incurred = CY)
  AE <- full_join_ids(AE_paid, AE_inc, by = c("Product","Peril")) %>% na0_numeric()
  
  gp_paid_E <- py_cy_split(d_paid, "Expected")
  gi_inc_E  <- py_cy_split(d_inc,  "Expected")
  E_paid <- three_block_ave_table(gp_paid_E$g_peril, gp_paid_E$g_prod) %>% 
    .force_char_ids %>% dplyr::rename(PY_Paid = PY, CY_Paid = CY)
  E_inc  <- three_block_ave_table(gi_inc_E$g_peril,  gi_inc_E$g_prod) %>% 
    .force_char_ids %>% dplyr::rename(PY_Incurred = PY, CY_Incurred = CY)
  E <- full_join_ids(E_paid, E_inc, by = c("Product","Peril")) %>% na0_numeric()
  
  summarise_class_totals <- function(d) {
    d_tot <- d %>% dplyr::filter(toupper(trimws(Peril)) == "TOTAL")
    if (!nrow(d_tot)) {
      d %>% dplyr::group_by(Product) %>%
        dplyr::summarise(
          PY_Paid     = sum(PY_Paid,     na.rm = TRUE),
          CY_Paid     = sum(CY_Paid,     na.rm = TRUE),
          PY_Incurred = sum(PY_Incurred, na.rm = TRUE),
          CY_Incurred = sum(CY_Incurred, na.rm = TRUE),
          .groups = "drop"
        ) %>% dplyr::mutate(Peril = "TOTAL")
    } else {
      d_tot %>% dplyr::group_by(Product, Peril) %>%
        dplyr::summarise(
          PY_Paid     = sum(PY_Paid,     na.rm = TRUE),
          CY_Paid     = sum(CY_Paid,     na.rm = TRUE),
          PY_Incurred = sum(PY_Incurred, na.rm = TRUE),
          CY_Incurred = sum(CY_Incurred, na.rm = TRUE),
          .groups = "drop"
        )
    }
  }
  
  AE_T <- summarise_class_totals(AE)
  E_T  <- summarise_class_totals(E)
  
  div   <- function(a, b) ifelse(b == 0, NA_real_, a / b)
  clamp <- function(v) pmax(pmin(v, 9.999), -9.999)
  
  M <- full_join_ids(AE_T, E_T, by = c("Product","Peril"), suffix = c("_AE","_E")) %>% na0_numeric() %>%
    dplyr::mutate(
      `PY Paid`        = clamp(div(PY_Paid_AE,     PY_Paid_E)),
      `CY Paid`        = clamp(div(CY_Paid_AE,     CY_Paid_E)),
      `Total Paid`     = clamp(div(PY_Paid_AE + CY_Paid_AE, PY_Paid_E + CY_Paid_E)),
      `PY Incurred`    = clamp(div(PY_Incurred_AE, PY_Incurred_E)),
      `CY Incurred`    = clamp(div(CY_Incurred_AE, CY_Incurred_E)),
      `Total Incurred` = clamp(div(PY_Incurred_AE + CY_Incurred_AE, PY_Incurred_E + CY_Incurred_E))
    ) %>%
    dplyr::select(Product, Peril, `PY Paid`, `PY Incurred`, `CY Paid`, `CY Incurred`, `Total Paid`, `Total Incurred`) %>%
    dplyr::mutate(`Class/Peril` = as.character(Product),
                  Peril         = as.character(Peril))
  
  grand <- tibble::tibble(
    `Class/Peril` = "Grand Total", Peril = "",
    `PY Paid`        = clamp(div(sum(AE_T$PY_Paid,        na.rm = TRUE), sum(E_T$PY_Paid,        na.rm = TRUE))),
    `CY Paid`        = clamp(div(sum(AE_T$CY_Paid,        na.rm = TRUE), sum(E_T$CY_Paid,        na.rm = TRUE))),
    `Total Paid`     = clamp(div(sum(AE_T$PY_Paid + AE_T$CY_Paid,         na.rm = TRUE),
                                 sum(E_T$PY_Paid + E_T$CY_Paid,           na.rm = TRUE))),
    `PY Incurred`    = clamp(div(sum(AE_T$PY_Incurred,    na.rm = TRUE), sum(E_T$PY_Incurred,    na.rm = TRUE))),
    `CY Incurred`    = clamp(div(sum(AE_T$CY_Incurred,    na.rm = TRUE), sum(E_T$CY_Incurred,    na.rm = TRUE))),
    `Total Incurred` = clamp(div(sum(AE_T$PY_Incurred + AE_T$CY_Incurred, na.rm = TRUE),
                                 sum(E_T$PY_Incurred + E_T$CY_Incurred,   na.rm = TRUE)))
  )
  
  out <- dplyr::bind_rows(
    M %>% dplyr::select(`Class/Peril`, Peril, `PY Paid`, `PY Incurred`, `CY Paid`, `CY Incurred`, `Total Paid`, `Total Incurred`),
    grand
  )
  
  # >>> THIS LINE makes first 3 columns IDENTICAL to the amounts sheet
  # IDs strictly text
  out <- out %>%
    dplyr::mutate(`Class/Peril` = factor(.data[["Class/Peril"]],
                                         levels = levels_product_gt_last(.data[["Class/Peril"]]))) %>%
    .force_text_ids_all %>%
    dplyr::mutate(Peril = trimws(Peril), `Class/Peril` = trimws(`Class/Peril`)) %>%
    dplyr::filter(Peril == "" | toupper(Peril) == "TOTAL" | grepl("[A-Za-z]", Peril))
  
  # First 3 columns identical to the amounts table: Peril, Class/Peril then metrics
  out <- out %>% dplyr::relocate(Peril, .before = `Class/Peril`)
  
  # Order classes A→Z (GT last), and perils A→Z with TOTAL last per class
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
  
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  out$Peril         <- as.character(out$Peril)
  
  return(out)
}
# <<< END ADD <<<
