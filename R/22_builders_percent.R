# R/22_builders_percent.R — percent tables (ratio calculations)

# Safe division with clamping
safe_divide <- function(a, b) {
  ifelse(b == 0 | is.na(b), NA_real_, a / b)
}

clamp_pct <- function(v, lower = -9.999, upper = 9.999) {
  pmax(pmin(v, upper), lower)
}

# Class Summary (percent) with TOTAL only per class
build_class_summary_pct <- function(df) {
  d_paid <- df %>% dplyr::filter(.data$Measure == "Paid")
  d_inc  <- df %>% dplyr::filter(.data$Measure == "Incurred")

  gp_paid_AE <- py_cy_split(d_paid, "A - E")
  gi_inc_AE  <- py_cy_split(d_inc,  "A - E")
  AE_paid <- three_block_ave_table(gp_paid_AE$g_peril, gp_paid_AE$g_prod) %>%
    .force_char_ids %>% dplyr::rename(PY_Paid = .data$PY, CY_Paid = .data$CY)
  AE_inc  <- three_block_ave_table(gi_inc_AE$g_peril,  gi_inc_AE$g_prod) %>%
    .force_char_ids %>% dplyr::rename(PY_Incurred = .data$PY, CY_Incurred = .data$CY)
  AE <- full_join_ids(AE_paid, AE_inc, by = c("Product","Peril")) %>% na0_numeric()

  gp_paid_E <- py_cy_split(d_paid, "Expected")
  gi_inc_E  <- py_cy_split(d_inc,  "Expected")
  E_paid <- three_block_ave_table(gp_paid_E$g_peril, gp_paid_E$g_prod) %>%
    .force_char_ids %>% dplyr::rename(PY_Paid = .data$PY, CY_Paid = .data$CY)
  E_inc  <- three_block_ave_table(gi_inc_E$g_peril,  gi_inc_E$g_prod) %>%
    .force_char_ids %>% dplyr::rename(PY_Incurred = .data$PY, CY_Incurred = .data$CY)
  E <- full_join_ids(E_paid, E_inc, by = c("Product","Peril")) %>% na0_numeric()

  summarise_class_totals <- function(d) {
    d_tot <- d %>% dplyr::filter(toupper(trimws(.data$Peril)) == "TOTAL")
    if (!nrow(d_tot)) {
      d %>% dplyr::group_by(.data$Product) %>%
        dplyr::summarise(
          PY_Paid     = sum(.data$PY_Paid,     na.rm = TRUE),
          CY_Paid     = sum(.data$CY_Paid,     na.rm = TRUE),
          PY_Incurred = sum(.data$PY_Incurred, na.rm = TRUE),
          CY_Incurred = sum(.data$CY_Incurred, na.rm = TRUE),
          .groups = "drop"
        ) %>% dplyr::mutate(Peril = "TOTAL")
    } else {
      d_tot %>% dplyr::group_by(.data$Product, .data$Peril) %>%
        dplyr::summarise(
          PY_Paid     = sum(.data$PY_Paid,     na.rm = TRUE),
          CY_Paid     = sum(.data$CY_Paid,     na.rm = TRUE),
          PY_Incurred = sum(.data$PY_Incurred, na.rm = TRUE),
          CY_Incurred = sum(.data$CY_Incurred, na.rm = TRUE),
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
      `PY Paid`        = clamp(div(.data$PY_Paid_AE,     .data$PY_Paid_E)),
      `CY Paid`        = clamp(div(.data$CY_Paid_AE,     .data$CY_Paid_E)),
      `Total Paid`     = clamp(div(.data$PY_Paid_AE + .data$CY_Paid_AE, .data$PY_Paid_E + .data$CY_Paid_E)),
      `PY Incurred`    = clamp(div(.data$PY_Incurred_AE, .data$PY_Incurred_E)),
      `CY Incurred`    = clamp(div(.data$CY_Incurred_AE, .data$CY_Incurred_E)),
      `Total Incurred` = clamp(div(.data$PY_Incurred_AE + .data$CY_Incurred_AE, .data$PY_Incurred_E + .data$CY_Incurred_E))
    ) %>%
    dplyr::select(.data$Product, .data$Peril, `PY Paid`, `PY Incurred`, `CY Paid`, `CY Incurred`, `Total Paid`, `Total Incurred`) %>%
    dplyr::mutate(`Class/Peril` = as.character(.data$Product),
                  Peril         = as.character(.data$Peril))

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
    M %>% dplyr::select(`Class/Peril`, .data$Peril, `PY Paid`, `PY Incurred`, `CY Paid`, `CY Incurred`, `Total Paid`, `Total Incurred`),
    grand
  )

  out <- out %>%
    dplyr::mutate(`Class/Peril` = factor(.data[["Class/Peril"]],
                                         levels = levels_product_gt_last(.data[["Class/Peril"]]))) %>%
    .force_text_ids_all %>%
    dplyr::mutate(Peril = trimws(.data$Peril), `Class/Peril` = trimws(.data$`Class/Peril`)) %>%
    dplyr::filter(.data$Peril == "" | toupper(.data$Peril) == "TOTAL" | grepl("[A-Za-z]", .data$Peril))

  out <- out %>% dplyr::relocate(.data$Peril, .before = `Class/Peril`)

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
      dplyr::mutate(Peril = factor(.data$Peril, levels = plv)) %>%
      dplyr::arrange(.data$Peril)
  })
  out <- dplyr::bind_rows(rebuild)

  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  out$Peril         <- as.character(out$Peril)

  return(out)
}

# Class Summary (percent) with Segment Group
build_class_summary_pct_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_summary_pct(d)
    if (!nrow(tbl)) return(tbl[0, ])
    tbl$`Segment (Group)` <- grp
    tbl
  }

  d_nig <- df %>% dplyr::filter(.data$Segment == "NIG")
  d_non <- df %>% dplyr::filter(.data$Segment != "NIG" | is.na(.data$Segment))

  out <- dplyr::bind_rows(make(d_nig, "NIG"), make(d_non, "Non NIG")) %>%
    .force_text_ids_all %>% ensure_id_cols() %>%
    dplyr::mutate(
      Peril         = trimws(as.character(.data$Peril)),
      `Class/Peril` = trimws(as.character(.data$`Class/Peril`))
    ) %>%
    dplyr::filter(.data$Peril == "" | toupper(.data$Peril) == "TOTAL" | !grepl("^[0-9]+$", .data$Peril)) %>%
    dplyr::relocate(.data$Peril, `Segment (Group)`, `Class/Peril`)

  if (nrow(out)) {
    out$`Class/Peril` <- factor(out$`Class/Peril`, levels = safe_levels_class(out$`Class/Peril`))

    rebuilt <- lapply(levels(out$`Class/Peril`), function(cls) {
      dsub <- dplyr::filter(out, `Class/Peril` == cls)
      plv  <- levels_peril_total_last(dsub$Peril)
      dsub %>%
        dplyr::mutate(Peril = factor(.data$Peril, levels = plv)) %>%
        dplyr::arrange(.data$Peril)
    })
    out <- dplyr::bind_rows(rebuilt)
  }

  out$Peril         <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)
  if (anyDuplicated(names(out))) out <- out[, !duplicated(names(out)), drop = FALSE]
  out <- .ids_text_guard(out)

  out
}

# Class × Peril (percent) with all perils visible
build_class_peril_summary_pct <- function(df) {
  d_paid <- df %>% dplyr::filter(.data$Measure == "Paid")
  d_inc  <- df %>% dplyr::filter(.data$Measure == "Incurred")

  gp_paid_AE <- py_cy_split(d_paid, "A - E")
  gi_inc_AE  <- py_cy_split(d_inc,  "A - E")
  AE_paid <- three_block_ave_table(gp_paid_AE$g_peril, gp_paid_AE$g_prod) %>% dplyr::rename(PY_Paid = .data$PY, CY_Paid = .data$CY)
  AE_inc  <- three_block_ave_table(gi_inc_AE$g_peril,  gi_inc_AE$g_prod)  %>% dplyr::rename(PY_Incurred = .data$PY, CY_Incurred = .data$CY)
  AE <- full_join_ids(AE_paid, AE_inc, by = c("Product","Peril")) %>% na0_numeric()

  gp_paid_E <- py_cy_split(d_paid, "Expected")
  gi_inc_E  <- py_cy_split(d_inc,  "Expected")
  E_paid <- three_block_ave_table(gp_paid_E$g_peril, gp_paid_E$g_prod) %>% dplyr::rename(PY_Paid = .data$PY, CY_Paid = .data$CY)
  E_inc  <- three_block_ave_table(gi_inc_E$g_peril,  gi_inc_E$g_prod)  %>% dplyr::rename(PY_Incurred = .data$PY, CY_Incurred = .data$CY)
  E <- full_join_ids(E_paid, E_inc, by = c("Product","Peril")) %>% na0_numeric()

  M <- full_join_ids(AE, E, by = c("Product","Peril"), suffix = c("_AE","_E")) %>% na0_numeric() %>% dplyr::ungroup()
  if (!nrow(M)) {
    return(tibble::tibble(`Class/Peril`=character(), Peril=character(),
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
    dplyr::select(.data$Product, .data$Peril, .data$PY_Paid, .data$PY_Incurred, .data$CY_Paid, .data$CY_Incurred, .data$Total_Paid, .data$Total_Incurred)

  if (!nrow(base)) {
    return(tibble::tibble(
      `Class/Peril` = character(), Peril = character(),
      `PY Paid` = numeric(), `PY Incurred` = numeric(),
      `CY Paid` = numeric(), `CY Incurred` = numeric(),
      `Total Paid` = numeric(), `Total Incurred` = numeric()
    ))
  }

  AE_T <- AE %>% dplyr::filter(.data$Peril == "TOTAL")
  E_T  <- E  %>% dplyr::filter(.data$Peril == "TOTAL")
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

  if ("Class/Peril" %in% names(base))  base[["Class/Peril"]]  <- NULL
  if ("Class/Peril" %in% names(grand)) grand[["Class/Peril"]] <- NULL

  out <- dplyr::bind_rows(base, grand) %>%
    dplyr::rename(
      `Class/Peril` = .data$Product,
      `PY Paid` = .data$PY_Paid, `PY Incurred` = .data$PY_Incurred,
      `CY Paid` = .data$CY_Paid, `CY Incurred` = .data$CY_Incurred,
      `Total Paid` = .data$Total_Paid, `Total Incurred` = .data$Total_Incurred
    )

  inner <- out %>% dplyr::filter(!.data$`Class/Peril` %in% c("Grand Total"))
  order_perils_then_total <- function(dfin) {
    dfin <- dfin %>%
      dplyr::mutate(`Class/Peril` = factor(.data$`Class/Peril`, levels = levels_product_gt_last(.data$`Class/Peril`)))
    outl <- list()
    for (cls in levels(dfin$`Class/Peril`)) {
      dsub <- dplyr::filter(dfin, `Class/Peril` == cls)
      peril_levels <- levels_peril_total_last(dsub$Peril)
      dsub <- dsub %>%
        dplyr::mutate(Peril = factor(.data$Peril, levels = peril_levels)) %>%
        dplyr::arrange(.data$Peril)
      outl[[length(outl)+1]] <- dsub
    }
    br_rows(outl)
  }
  inner <- order_perils_then_total(inner)
  tail  <- out %>% dplyr::filter(.data$`Class/Peril` %in% c("Grand Total"))
  final <- bind_rows_ids(inner, tail)

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
      dplyr::mutate(Peril = factor(.data$Peril, levels = plv)) %>%
      dplyr::arrange(.data$Peril)
  })
  final <- dplyr::bind_rows(rebuild)

  final$`Class/Peril` <- as.character(final$`Class/Peril`)
  final$Peril         <- as.character(final$Peril)

  if (anyDuplicated(names(final))) {
    keep <- !duplicated(names(final))
    final <- final[ , keep, drop = FALSE]
  }

  return(final)
}

# Class × Peril (percent) with Segment Group
build_class_peril_summary_pct_with_segment <- function(df) {
  make <- function(d, grp) {
    tbl <- build_class_peril_summary_pct(d)
    if (!nrow(tbl)) return(tbl)
    tbl$`Segment (Group)` <- grp
    tbl
  }
  d_nig <- df %>% dplyr::filter(.data$Segment == "NIG")
  d_non <- df %>% dplyr::filter(.data$Segment != "NIG" | is.na(.data$Segment))

  out <- dplyr::bind_rows(make(d_nig, "NIG"), make(d_non, "Non NIG")) %>%
    .force_text_ids_all %>% ensure_id_cols() %>%
    dplyr::mutate(
      Peril         = trimws(as.character(.data$Peril)),
      `Class/Peril` = trimws(as.character(.data$`Class/Peril`))
    ) %>%
    dplyr::filter(.data$Peril == "" | toupper(.data$Peril) == "TOTAL" | !grepl("^[0-9]+$", .data$Peril)) %>%
    dplyr::relocate(.data$Peril, `Segment (Group)`, `Class/Peril`)

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
      dplyr::mutate(Peril = factor(.data$Peril, levels = plv)) %>%
      dplyr::arrange(.data$Peril)
  })
  out <- dplyr::bind_rows(rebuild)

  out$Peril <- as.character(out$Peril)
  out$`Class/Peril` <- as.character(out$`Class/Peril`)

  if (anyDuplicated(names(out))) { keep <- !duplicated(names(out)); out <- out[, keep, drop = FALSE] }
  out <- .ids_text_guard(out)

  out
}
