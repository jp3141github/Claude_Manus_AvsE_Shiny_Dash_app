# R/21_builders_amounts.R — amounts tables

# Class Summary (amounts), TOTAL only per class, then GT & Check
build_class_summary <- function(df) {
  merged <- class_summary_core(df)

  class_only <- merged %>%
    dplyr::filter(toupper(trimws(.data$Peril)) == "TOTAL") %>%
    dplyr::select(.data$Product, .data$PY_Paid, .data$PY_Incurred, .data$CY_Paid, .data$CY_Incurred,
                  .data$Total_Paid, .data$Total_Incurred)

  metric_cols <- c("PY_Paid","PY_Incurred","CY_Paid","CY_Incurred","Total_Paid","Total_Incurred")
  if (!nrow(class_only)) {
    class_only <- tibble::tibble(Product = character(),
                                 !!!setNames(rep(list(numeric()), length(metric_cols)), metric_cols))
  } else {
    class_only <- class_only %>%
      dplyr::mutate(dplyr::across(dplyr::all_of(metric_cols), ~ suppressWarnings(as.numeric(.x))))
  }

  zero_mask <- if (nrow(class_only)) rowSums(abs(as.data.frame(class_only[metric_cols])), na.rm = TRUE) == 0 else logical(0)
  class_only <- class_only[!zero_mask, , drop = FALSE]

  gt <- tibble::tibble(
    Product = "Grand Total",
    PY_Paid = sum(class_only$PY_Paid, na.rm = TRUE),
    PY_Incurred = sum(class_only$PY_Incurred, na.rm = TRUE),
    CY_Paid = sum(class_only$CY_Paid, na.rm = TRUE),
    CY_Incurred = sum(class_only$CY_Incurred, na.rm = TRUE),
    Total_Paid = sum(class_only$Total_Paid, na.rm = TRUE),
    Total_Incurred = sum(class_only$Total_Incurred, na.rm = TRUE)
  )

  check <- tibble::tibble(
    Product="Check",
    PY_Paid=0, PY_Incurred=0, CY_Paid=0, CY_Incurred=0, Total_Paid=0, Total_Incurred=0
  )

  class_only <- dplyr::bind_rows(class_only, gt, check)

  num_cols <- setdiff(names(class_only), "Product")
  class_only[num_cols] <- lapply(class_only[num_cols], function(x) suppressWarnings(as.numeric(x)) / 1e6)

  class_only %>%
    dplyr::rename(`Class/Peril` = .data$Product,
                  `PY Paid` = .data$PY_Paid, `PY Incurred` = .data$PY_Incurred,
                  `CY Paid` = .data$CY_Paid, `CY Incurred` = .data$CY_Incurred,
                  `Total Paid` = .data$Total_Paid, `Total Incurred` = .data$Total_Incurred) %>%
    dplyr::mutate(Peril = "TOTAL") %>%
    dplyr::relocate(.data$Peril, .before = `Class/Peril`)
}

# Class Summary (amounts) with Segment Group
build_class_summary_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_summary(d)
    if (!nrow(tbl)) return(tbl)
    tbl$`Segment (Group)` <- grp
    tbl
  }

  d_nig <- df %>% dplyr::filter(.data$Segment == "NIG")
  d_non <- df %>% dplyr::filter(.data$Segment != "NIG" | is.na(.data$Segment))

  out <- dplyr::bind_rows(make(d_nig, "NIG"), make(d_non, "Non NIG")) %>%
    .force_text_ids_all %>% ensure_id_cols() %>%
    dplyr::mutate(Peril = as.character(.data$Peril),
                  `Class/Peril` = as.character(`Class/Peril`)) %>%
    dplyr::relocate(.data$Peril, `Segment (Group)`, `Class/Peril`) %>%
    dplyr::mutate(Peril = trimws(.data$Peril), `Class/Peril` = trimws(`Class/Peril`)) %>%
    dplyr::filter(.data$Peril == "" | toupper(.data$Peril) == "TOTAL" | grepl("[A-Za-z]", .data$Peril)) %>%
    { .$`Class/Peril` <- factor(as.character(.$`Class/Peril`), levels = safe_levels_class(.$`Class/Peril`)); . }

  cls_levels <- levels(out$`Class/Peril`)
  rebuild <- lapply(cls_levels, function(cls) {
    dsub <- dplyr::filter(out, `Class/Peril` == cls)
    plv  <- levels_peril_total_last(dsub$Peril)
    dsub %>%
      dplyr::mutate(Peril = factor(.data$Peril, levels = plv)) %>%
      dplyr::arrange(.data$Peril)
  })
  out <- dplyr::bind_rows(rebuild)

  out$Peril <- as.character(out$Peril); out$`Class/Peril` <- as.character(out$`Class/Peril`)
  if (anyDuplicated(names(out))) out <- out[, !duplicated(names(out)), drop = FALSE]
  out
}

# Class × Peril (amounts, £m) with TOTAL lines and overall GT
build_class_peril_summary <- function(df) {
  merged <- class_summary_core(df)
  need <- c("PY_Paid","PY_Incurred","CY_Paid","CY_Incurred","Total_Paid","Total_Incurred")
  for (nm in need) if (!(nm %in% names(merged))) merged[[nm]] <- 0

  keep_cols <- c("Product","Peril", need)
  out <- merged %>%
    dplyr::select(dplyr::all_of(keep_cols)) %>%
    dplyr::mutate(dplyr::across(-c(.data$Product, .data$Peril), ~ suppressWarnings(as.numeric(.)))) %>%
    {
      lv_prod <- levels_product_gt_last(.$Product)
      lv_per  <- levels_peril_total_last(.$Peril)
      .$Product <- factor(as.character(.$Product), levels = lv_prod)
      .$Peril   <- factor(as.character(.$Peril),   levels = lv_per)
      .
    } %>%
    dplyr::arrange(.data$Product, .data$Peril)

  metric_cols <- setdiff(names(out), c("Product","Peril"))
  if (nrow(out)) {
    out <- out[rowSums(abs(as.data.frame(out[metric_cols])), na.rm = TRUE) != 0, , drop = FALSE]
  }

  class_totals <- out %>%
    dplyr::filter(toupper(trimws(.data$Peril)) == "TOTAL") %>%
    dplyr::group_by(.data$Product) %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(metric_cols), ~ sum(.x, na.rm = TRUE)), .groups = "drop")

  grand <- tibble::tibble(Product = "Grand Total", Peril = "")
  for (nm in metric_cols) grand[[nm]] <- sum(class_totals[[nm]], na.rm = TRUE)

  out[metric_cols]   <- lapply(out[metric_cols],   function(x) suppressWarnings(as.numeric(x)) / 1e6)
  grand[metric_cols] <- lapply(grand[metric_cols], function(x) suppressWarnings(as.numeric(x)) / 1e6)

  final <- dplyr::bind_rows(out, grand) %>%
    dplyr::rename(`Class/Peril` = .data$Product) %>%
    dplyr::relocate(.data$Peril, .before = `Class/Peril`)

  final$Peril <- as.character(final$Peril); final$`Class/Peril` <- as.character(final$`Class/Peril`)
  final
}

# With Segment Group variant
build_class_peril_summary_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_peril_summary(d)
    if (!nrow(tbl)) return(tbl)
    tbl$`Segment (Group)` <- grp
    tbl
  }

  d_nig <- df %>% dplyr::filter(.data$Segment == "NIG")
  d_non <- df %>% dplyr::filter(.data$Segment != "NIG" | is.na(.data$Segment))

  out <- dplyr::bind_rows(make(d_nig, "NIG"), make(d_non, "Non NIG")) %>%
    .force_text_ids_all %>% ensure_id_cols() %>%
    dplyr::mutate(Peril=as.character(.data$Peril), `Class/Peril`=as.character(`Class/Peril`)) %>%
    dplyr::relocate(.data$Peril, `Segment (Group)`, `Class/Peril`) %>%
    dplyr::mutate(Peril = trimws(.data$Peril), `Class/Peril` = trimws(`Class/Peril`)) %>%
    dplyr::filter(.data$Peril == "" | toupper(.data$Peril) == "TOTAL" | grepl("[A-Za-z]", .data$Peril)) %>%
    { .$`Class/Peril` <- factor(as.character(.$`Class/Peril`), levels = safe_levels_class(.$`Class/Peril`)); . }

  cls_levels <- levels(out$`Class/Peril`)
  rebuild <- lapply(cls_levels, function(cls) {
    dsub <- dplyr::filter(out, `Class/Peril` == cls)
    plv  <- levels_peril_total_last(dsub$Peril)
    dsub %>% dplyr::mutate(Peril = factor(.data$Peril, levels = plv)) %>% dplyr::arrange(.data$Peril)
  })
  out <- dplyr::bind_rows(rebuild)

  out$Peril <- as.character(out$Peril); out$`Class/Peril` <- as.character(out$`Class/Peril`)
  if (anyDuplicated(names(out))) out <- out[, !duplicated(names(out)), drop = FALSE]
  out
}
