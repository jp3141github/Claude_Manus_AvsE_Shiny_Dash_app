# R/32_charts_heatmaps.R — Heatmap chart functions (A-E by Basis and Year)

# Combined heatmap (Paid + Incurred) using ggplot
ts_gg_heatmap_ae <- function(total_summary) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  ax <- year_axis(years)

  df <- dplyr::bind_rows(
    tibble::tibble(Basis = "Paid",     Year = years, AE = as.numeric(ts_slice(total_summary, "Paid",     "A-E"))),
    tibble::tibble(Basis = "Incurred", Year = years, AE = as.numeric(ts_slice(total_summary, "Incurred", "A-E")))
  )

  ggplot2::ggplot(
    df,
    ggplot2::aes(x = factor(.data$Year, levels = ax$breaks, labels = ax$labels),
                 y = .data$Basis, fill = .data$AE)
  ) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_fill_gradient2(low = "#2ca02c", mid = "#ffffff", high = "#d62728", midpoint = 0) +
    ggplot2::labs(title = "A-E Heatmap (Favourable → Green, Adverse → Red)", x = NULL, y = NULL) +
    ggplot2::theme_minimal()
}

# Peril-level heatmap (amounts table)
heatmap_peril_amounts <- function(df_amt, col_value, title, fname, out_root) {
  d <- df_amt %>%
    dplyr::filter(.data$Peril != "", toupper(.data$Peril) != "TOTAL",
                  !.data$`Class/Peril` %in% c("Grand Total", "Check")) %>%
    dplyr::select(Product = .data$`Class/Peril`, Peril = .data$Peril, value = .data[[col_value]])
  if (!nrow(d)) return(NULL)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$Peril, y = .data$Product, fill = .data$value)) +
    ggplot2::geom_tile() +
    ggplot2::labs(title = title, x = NULL, y = NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  ggsave_raw(p, fname, out_dir = ensure_dir(out_root))
}

# Product × Year heatmap (Product as rows, Years as columns, with A-E color)
ts_heatmap_product_year <- function(ave_df, basis = c("Paid","Incurred"), out_dir = NULL) {
  basis <- match.arg(basis)
  years <- ts_year_cols(ave_df); if (!length(years)) return(NULL)

  # Filter out TOTAL rows and Grand Total
  d <- ave_df %>%
    dplyr::filter(!.data$Product %in% c("Grand Total", "Check"),
                  toupper(trimws(.data$Peril)) == "TOTAL")

  if (!nrow(d)) return(NULL)

  # Pivot to long format (Product × Year)
  d_long <- d %>%
    tidyr::pivot_longer(cols = dplyr::all_of(as.character(years)),
                        names_to = "Year", values_to = "AE") %>%
    dplyr::mutate(Year = as.integer(.data$Year),
                  AE = as.numeric(.data$AE))

  ax <- year_axis(years)

  p <- ggplot2::ggplot(d_long, ggplot2::aes(
    x = factor(.data$Year, levels = ax$breaks, labels = ax$labels),
    y = .data$Product,
    fill = .data$AE
  )) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_fill_gradient2(low = "#2ca02c", mid = "#ffffff", high = "#d62728", midpoint = 0) +
    ggplot2::labs(title = glue::glue("{basis} A-E Heatmap: Product × Year"),
                  x = NULL, y = NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  if (!is.null(out_dir)) {
    ggsave_raw(p, glue::glue("Heatmap_{basis}_Product_Year"), out_dir = ensure_dir(out_dir))
  } else {
    p
  }
}

# Static PNG export for combined heatmap
ts_plot_heatmap_ae <- function(total_summary, out_dir = NULL) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)

  df <- dplyr::bind_rows(
    tibble::tibble(Basis = "Paid",     Year = years, AE = as.numeric(ts_slice(total_summary, "Paid",     "A-E"))),
    tibble::tibble(Basis = "Incurred", Year = years, AE = as.numeric(ts_slice(total_summary, "Incurred", "A-E")))
  )

  ax <- year_axis(years)
  g <- ggplot2::ggplot(df, ggplot2::aes(
    x = factor(.data$Year, levels = ax$breaks, labels = ax$labels),
    y = .data$Basis,
    fill = .data$AE
  )) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_fill_gradient2(low = "#2ca02c", mid = "#ffffff", high = "#d62728", midpoint = 0) +
    ggplot2::labs(title = "A-E Heatmap", x = NULL, y = NULL) +
    ggplot2::theme_minimal()

  list(ggsave_raw(g, "Heatmap_AE_Paid_Incurred", out_dir = out_dir))
}
