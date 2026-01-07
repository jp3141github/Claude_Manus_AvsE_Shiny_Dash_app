# R/35_charts_png_pack.R — PNG pack generation (static chart exports)

# ---------- Time-series & chart helpers (gg) ----------
ts_gg_lines_with_ae <- function(total_summary, basis = c("Paid","Incurred")) {
  basis <- match.arg(basis)
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  ax <- year_axis(years)
  
  actual   <- ts_slice(total_summary, basis, "Actual")
  expected <- ts_slice(total_summary, basis, "Expected")
  diff     <- ts_slice(total_summary, basis, "A-E")
  
  df_line <- tibble::tibble(Year = years,
                            Actual = as.numeric(actual),
                            Expected = as.numeric(expected)) |>
    tidyr::pivot_longer(c("Actual","Expected"), names_to = "Series", values_to = "Value")
  df_bar  <- tibble::tibble(Year = years, AE = as.numeric(diff))
  
  ggplot2::ggplot() +
    ggplot2::geom_col(data = df_bar, ggplot2::aes(x = Year, y = AE), alpha = 0.35) +
    ggplot2::geom_line(data = df_line, ggplot2::aes(x = Year, y = Value, linetype = Series, colour = Series)) +
    ggplot2::geom_point(data = df_line, ggplot2::aes(x = Year, y = Value, colour = Series)) +
    ggplot2::scale_linetype_manual(values = LINE_TYPES) +
    ggplot2::scale_color_manual(values = LINE_COLOURS) +
    ggplot2::scale_x_continuous(breaks = ax$breaks, labels = ax$labels, expand = ggplot2::expansion(mult = c(0.01, 0.01))) +
    ggplot2::labs(title = glue::glue("{basis}: Actual vs Expected with A-E"),
                  x = "Accident Year", y = "Actual / Expected (£m)") +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
}

ts_gg_heatmap_ae <- function(total_summary) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  ax <- year_axis(years)
  
  df <- dplyr::bind_rows(
    tibble::tibble(Basis = "Paid",     Year = years, AE = as.numeric(ts_slice(total_summary, "Paid",     "A-E"))),
    tibble::tibble(Basis = "Incurred", Year = years, AE = as.numeric(ts_slice(total_summary, "Incurred", "A-E")))
  )
  
  ggplot2::ggplot(
    df,
    ggplot2::aes(x = factor(Year, levels = ax$breaks, labels = ax$labels),
                 y = Basis, fill = AE)
  ) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_fill_gradient2(low = "#2ca02c", mid = "#ffffff", high = "#d62728", midpoint = 0) +
    ggplot2::labs(title = "A-E Heatmap (Favourable → Green, Adverse → Red)", x = NULL, y = NULL) +
    ggplot2::theme_minimal()
}

ts_gg_variance_bridge <- function(total_summary) {
  grand <- function(df, basis, kind) {
    row <- dplyr::filter(df, Basis == basis, `A vs E` == kind)
    if (nrow(row) == 0) return(0.0)
    as.numeric(row$`Grand Total`[1])
  }
  
  cats     <- c("Paid","Incurred")
  expected <- sapply(cats, function(b) grand(total_summary, b, "Expected"))
  actual   <- sapply(cats, function(b) grand(total_summary, b, "Actual"))
  diff     <- actual - expected
  
  df <- tibble::tibble(
    Basis = rep(cats, each = 2),
    Type  = rep(c("Expected","Actual"), times = length(cats)),
    Value = c(rbind(expected, actual))
  )
  
  ggplot2::ggplot(df, ggplot2::aes(x = Basis, y = Value, fill = Type)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.7), width = 0.6) +
    ggplot2::scale_fill_manual(values = c("Expected" = COL_EXPECTED, "Actual" = COL_ACTUAL)) +
    ggplot2::geom_text(
      data = tibble::tibble(
        Basis = cats,
        y     = pmax(expected, actual) * 1.02,
        lbl   = paste0("A-E: ", ts_fmt(diff, 2))
      ),
      ggplot2::aes(x = Basis, y = y, label = lbl),
      inherit.aes = FALSE, vjust = 0
    ) +
    ggplot2::labs(title = "Variance by Basis (Expected vs Actual)",
                  y = "Grand Total (£m)", x = NULL) +
    ggplot2::theme_minimal()
}

# ---------- Static PNG chart builders ----------
ts_plot_lines_with_ae <- function(total_summary, out_dir = NULL) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)
  pngs <- list()
  
  for (basis in c("Paid","Incurred")) {
    actual   <- ts_slice(total_summary, basis, "Actual")
    expected <- ts_slice(total_summary, basis, "Expected")
    diff     <- ts_slice(total_summary, basis, "A-E")
    
    df_line <- tibble::tibble(Year = years, Actual = as.numeric(actual), Expected = as.numeric(expected)) |>
      tidyr::pivot_longer(c("Actual","Expected"), names_to = "Series", values_to = "Value")
    df_bar  <- tibble::tibble(Year = years, AE = as.numeric(diff))
    
    p <- ggplot2::ggplot() +
      ggplot2::geom_col(data = df_bar, ggplot2::aes(x = Year, y = AE), alpha = 0.35) +
      ggplot2::geom_line(data = df_line, ggplot2::aes(x = Year, y = Value, linetype = Series, colour = Series)) +
      ggplot2::geom_point(data = df_line, ggplot2::aes(x = Year, y = Value, colour = Series)) +
      ggplot2::scale_linetype_manual(values = LINE_TYPES) +
      ggplot2::scale_color_manual(values = LINE_COLOURS) +
      ggplot2::labs(title = glue::glue("{basis}: Actual vs Expected with A-E"),
                    x = "Accident Year", y = "Actual / Expected (£m)") +
      ggplot2::theme_minimal() +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
    
    pngs[[length(pngs) + 1]] <-
      ggsave_raw(p, filename = glue::glue("lines_ae_{tolower(basis)}"), out_dir = out_dir)
  }
  pngs
}

ts_plot_waterfall_ae <- function(total_summary, out_dir = NULL) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)
  pngs <- list()
  
  for (basis in c("Paid","Incurred")) {
    vals <- ts_slice(total_summary, basis, "A-E"); if (!length(vals)) next
    
    running <- cumsum(replace(as.numeric(vals), is.na(vals), 0))
    starts  <- c(0, head(running, -1))
    ends    <- starts + as.numeric(vals)
    
    df <- tibble::tibble(
      Year  = years,
      Start = starts,
      End   = ends,
      Value = as.numeric(vals),
      Dir   = ifelse(as.numeric(vals) >= 0, "Up (bad)", "Down (good)")
    )
    
    p <- ggplot2::ggplot(df) +
      ggplot2::geom_rect(
        ggplot2::aes(xmin = as.numeric(factor(Year)) - 0.45,
                     xmax = as.numeric(factor(Year)) + 0.45,
                     ymin = Start, ymax = End, fill = Dir)
      ) +
      ggplot2::scale_fill_manual(values = c("Down (good)" = "#2E7D32",  # green
                                            "Up (bad)"   = "#D32F2F"),  # red
                                 guide = "none") +
      ggplot2::geom_hline(yintercept = 0) +
      ggplot2::labs(title = glue::glue("{basis}: A-E Waterfall by Accident Year"),
                    x = "Accident Year", y = "Cumulative A-E (£m)") +
      ggplot2::theme_minimal()
    
    pngs[[length(pngs) + 1]] <-
      ggsave_raw(p, filename = glue::glue("waterfall_ae_{tolower(basis)}"), out_dir = out_dir)
  }
  pngs
}

ts_plot_heatmap_ae <- function(total_summary, out_dir = NULL) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)
  
  df <- dplyr::bind_rows(
    tibble::tibble(Basis="Paid",     Year=years, AE=as.numeric(ts_slice(total_summary, "Paid","A-E"))),
    tibble::tibble(Basis="Incurred", Year=years, AE=as.numeric(ts_slice(total_summary, "Incurred","A-E")))
  )
  
  p <- ggplot2::ggplot(df, ggplot2::aes(x = factor(Year), y = Basis, fill = AE)) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_fill_gradient2(low = "#2ca02c", mid = "#ffffff", high = "#d62728", midpoint = 0) +
    ggplot2::labs(title = "A-E Heatmap (Favourable → Green, Adverse → Red)", x = NULL, y = NULL) +
    ggplot2::theme_minimal()
  
  list( ggsave_raw(p, filename = "heatmap_ae", out_dir = out_dir, width = 12, height = 3.2) )
}

ts_plot_variance_bridge <- function(total_summary, out_dir = NULL) {
  grand <- function(df, basis, kind) {
    row <- dplyr::filter(df, Basis == basis, `A vs E` == kind)
    if (nrow(row) == 0) return(0.0)
    as.numeric(row$`Grand Total`[1])
  }
  cats     <- c("Paid","Incurred")
  expected <- sapply(cats, function(b) grand(total_summary, b, "Expected"))
  actual   <- sapply(cats, function(b) grand(total_summary, b, "Actual"))
  diff     <- actual - expected
  
  df <- tibble::tibble(
    Basis = rep(cats, each = 2),
    Type  = rep(c("Expected","Actual"), times = length(cats)),
    Value = c(rbind(expected, actual))
  )
  
  p <- ggplot2::ggplot(df, ggplot2::aes(x = Basis, y = Value, fill = Type)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.7), width = 0.6) +
    ggplot2::scale_fill_manual(values = c("Expected" = COL_EXPECTED, "Actual" = COL_ACTUAL)) +
    ggplot2::geom_text(
      data = tibble::tibble(
        Basis = cats,
        y     = pmax(expected, actual) * 1.02,
        lbl   = paste0("A-E: ", ts_fmt(diff, 2))
      ),
      ggplot2::aes(x = Basis, y = y, label = lbl),
      inherit.aes = FALSE, vjust = 0
    ) +
    ggplot2::labs(title = "Variance by Basis (Expected vs Actual)",
                  y = "Grand Total (£m)", x = NULL) +
    ggplot2::theme_minimal()
  
  list( ggsave_raw(p, filename = "variance_bridge_basis", out_dir = out_dir, width = 8, height = 4.5) )
}

ts_plot_cumulative_trend <- function(total_summary, out_dir = NULL) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)
  pngs <- list()
  
  for (basis in c("Paid","Incurred")) {
    actual   <- cumsum(as.numeric(ts_slice(total_summary, basis, "Actual")))
    expected <- cumsum(as.numeric(ts_slice(total_summary, basis, "Expected")))
    
    df <- tibble::tibble(Year = years,
                         `Actual (agg)`   = actual,
                         `Expected (agg)` = expected) |>
      tidyr::pivot_longer(-Year, names_to = "Series", values_to = "Value")
    
    p <- ggplot2::ggplot(df, ggplot2::aes(x = Year, y = Value, linetype = Series, colour = Series)) +
      ggplot2::geom_line() + ggplot2::geom_point() +
      ggplot2::scale_linetype_manual(values = LINE_TYPES_CUM) +
      ggplot2::scale_color_manual(values = LINE_COLOURS_CUM) +
      ggplot2::labs(title = glue::glue("{basis}: Cumulative Actual vs Expected"),
                    x = "Accident Year", y = "Cumulative (£m)") +
      ggplot2::theme_minimal()
    
    pngs[[length(pngs) + 1]] <-
      ggsave_raw(p, filename = glue::glue("cumulative_{tolower(basis)}"), out_dir = out_dir)
  }
  pngs
}

ts_make_all_charts <- function(total_summary, out_dir = NULL) {
  out_dir <- ts_ensure_dir(out_dir)
  if (is.null(total_summary) || !nrow(total_summary)) return(list())
  
  fns <- list(
    ts_plot_lines_with_ae,
    ts_plot_waterfall_ae,
    ts_plot_heatmap_ae,
    ts_plot_variance_bridge,
    ts_plot_cumulative_trend
  )
  
  pngs <- list()
  for (fn in fns) {
    out <- tryCatch(fn(total_summary, out_dir = fs::path(out_dir, "total_summary")),
                    error = function(e) NULL)
    if (!is.null(out)) pngs <- c(pngs, out)
  }
  pngs
}

# ---- Extra chart pack (folders like Python) ----
ensure_dir <- function(p) { if (!is.null(p) && nzchar(p)) fs::dir_create(p, recurse=TRUE); p }

plot_paid_ave_per_product <- function(paid_ave_df, out_root=NULL) {
  yrs <- ts_year_cols(paid_ave_df); if (!length(yrs)) return(list())
  out <- list()
  
  agg <- paid_ave_df %>%
    dplyr::group_by(Peril) %>%
    dplyr::summarise(dplyr::across(all_of(as.character(yrs)), ~ sum(.x, na.rm = TRUE)), .groups="drop")
  
  d_all <- agg %>%
    dplyr::filter(toupper(Peril)!="TOTAL") %>%
    tidyr::pivot_longer(cols=all_of(as.character(yrs)), names_to="Year", values_to="AE")
  
  p_all <- ggplot2::ggplot(d_all, ggplot2::aes(x=as.integer(Year), y=AE, colour=Peril)) +
    ggplot2::geom_line() + ggplot2::geom_point() +
    ggplot2::labs(title="Paid AvE – All products (perils)", x="Accident Year", y="A-E (£m)") +
    ggplot2::theme_minimal()
  
  out[[length(out)+1]] <- ggsave_raw(p_all, "Paid_AvE_all_products_lines",
                                     out_dir=ensure_dir(fs::path(out_root,"Paid_AvE")))
  
  for (prod in unique(paid_ave_df$Product)) {
    d <- paid_ave_df %>%
      dplyr::filter(Product==prod, toupper(Peril)!="TOTAL") %>%
      tidyr::pivot_longer(cols=all_of(as.character(yrs)), names_to="Year", values_to="AE")
    if (!nrow(d)) next
    
    p <- ggplot2::ggplot(d, ggplot2::aes(x=as.integer(Year), y=AE, colour=Peril)) +
      ggplot2::geom_line() + ggplot2::geom_point() +
      ggplot2::labs(title=paste0("Paid AvE – ", prod, " perils"),
                    x="Accident Year", y="A-E (£m)") +
      ggplot2::theme_minimal()
    
    safe_name <- gsub("[^A-Za-z0-9]+","_", prod)
    out[[length(out)+1]] <- ggsave_raw(p, paste0("Paid_AvE_", safe_name, "_perils_lines"),
                                       out_dir=fs::path(out_root,"Paid_AvE"))
  }
  out
}

heatmap_peril_amounts <- function(df_amt, col_value, title, fname, out_root) {
  d <- df_amt %>%
    dplyr::filter(Peril!="", toupper(Peril)!="TOTAL",
                  !`Class/Peril` %in% c("Grand Total","Check")) %>%
    dplyr::select(Product=`Class/Peril`, Peril, value=.data[[col_value]])
  if (!nrow(d)) return(NULL)
  
  p <- ggplot2::ggplot(d, ggplot2::aes(x=Peril, y=Product, fill=value)) +
    ggplot2::geom_tile() +
    ggplot2::labs(title=title, x=NULL, y=NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x=ggplot2::element_text(angle=45, hjust=1))
  
  ggsave_raw(p, fname, out_dir=ensure_dir(out_root))
}

bar_class_totals <- function(df_amt, col_value, title, fname, out_root) {
  d <- df_amt %>%
    dplyr::filter(Peril=="TOTAL", !`Class/Peril` %in% c("Grand Total","Check")) %>%
    dplyr::select(Product=`Class/Peril`, value=.data[[col_value]])
  if (!nrow(d)) return(NULL)
  
  p <- ggplot2::ggplot(d, ggplot2::aes(x=reorder(Product, value), y=value)) +
    ggplot2::geom_col() + ggplot2::coord_flip() +
    ggplot2::labs(title=title, x=NULL, y=col_value) +
    ggplot2::theme_minimal()
  
  ggsave_raw(p, fname, out_dir=ensure_dir(out_root))
}

make_full_chart_pack <- function(tables, charts_base_dir = NULL) {
  if (is.null(charts_base_dir)) return(list())
  
  dir_total  <- fs::path(charts_base_dir, "total_summary")
  dir_cps    <- fs::path(charts_base_dir, "class_peril_summary")
  dir_cpspct <- fs::path(charts_base_dir, "class_peril_summary_pct")
  dir_cs     <- fs::path(charts_base_dir, "class_summary")
  dir_cspct  <- fs::path(charts_base_dir, "class_summary_pct")
  ensure_dir(dir_total); ensure_dir(dir_cps); ensure_dir(dir_cpspct); ensure_dir(dir_cs); ensure_dir(dir_cspct)
  
  # Total Summary pack
  ts_make_all_charts(tables[["Total Summary"]], out_dir = dir_total)
  
  # Paid AvE pack (ALL + per product)
  invisible(plot_paid_ave_per_product(tables[[SHEET_NAMES$paid_ave]], out_root = charts_base_dir))
  
  # Heatmaps (amounts)
  heatmap_peril_amounts(tables[["Class Peril Summary"]], "Total Paid",
                        "Heatmap – Paid by Product × Peril (A-E £m)", "heatmap_paid_product_peril",
                        out_root = dir_cps)
  heatmap_peril_amounts(tables[["Class Peril Summary"]], "Total Incurred",
                        "Heatmap – Incurred by Product × Peril (A-E £m)", "heatmap_incurred_product_peril",
                        out_root = dir_cps)
  
  # Heatmaps (%)
  heatmap_peril_amounts(tables[["Class Peril Summary pct"]], "Total Paid",
                        "Heatmap – Paid A:E % by Product × Peril", "heatmap_pct_paid_product_peril",
                        out_root = dir_cpspct)
  heatmap_peril_amounts(tables[["Class Peril Summary pct"]], "Total Incurred",
                        "Heatmap – Incurred A:E % by Product × Peril", "heatmap_pct_incurred_product_peril",
                        out_root = dir_cpspct)
  
  # Class totals bars
  bar_class_totals(tables[["Class Summary"]],     "Total Paid",
                   "Class totals – Paid A-E (£m)", "class_summary_all_products_totals",
                   out_root = dir_cs)
  bar_class_totals(tables[["Class Summary pct"]], "Total Paid",
                   "Class totals – Paid A:E %",    "class_summary_pct_all_products_totals",
                   out_root = dir_cspct)
}
