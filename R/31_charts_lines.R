# R/31_charts_lines.R — Line chart functions (Actual vs Expected with A-E)

# Time-series line chart with A-E bars (ggplot)
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
    ggplot2::geom_col(data = df_bar, ggplot2::aes(x = .data$Year, y = .data$AE), alpha = 0.35) +
    ggplot2::geom_line(data = df_line, ggplot2::aes(x = .data$Year, y = .data$Value, linetype = .data$Series, colour = .data$Series)) +
    ggplot2::geom_point(data = df_line, ggplot2::aes(x = .data$Year, y = .data$Value, colour = .data$Series)) +
    ggplot2::scale_linetype_manual(values = LINE_TYPES) +
    ggplot2::scale_color_manual(values = LINE_COLOURS) +
    ggplot2::scale_x_continuous(breaks = ax$breaks, labels = ax$labels, expand = ggplot2::expansion(mult = c(0.01, 0.01))) +
    ggplot2::labs(title = glue::glue("{basis}: Actual vs Expected with A-E"),
                  x = "Accident Year", y = "Actual / Expected (£m)") +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
}

# Static PNG export for line charts
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

    ax <- year_axis(years)
    g <- ggplot2::ggplot() +
      ggplot2::geom_col(data = df_bar, ggplot2::aes(x = .data$Year, y = .data$AE), alpha = 0.35) +
      ggplot2::geom_line(data = df_line, ggplot2::aes(x = .data$Year, y = .data$Value, linetype = .data$Series, colour = .data$Series)) +
      ggplot2::geom_point(data = df_line, ggplot2::aes(x = .data$Year, y = .data$Value, colour = .data$Series)) +
      ggplot2::scale_linetype_manual(values = LINE_TYPES) +
      ggplot2::scale_color_manual(values = LINE_COLOURS) +
      ggplot2::scale_x_continuous(breaks = ax$breaks, labels = ax$labels) +
      ggplot2::labs(title = glue::glue("{basis}: Actual vs Expected with A-E"),
                    x = "Accident Year", y = "£m") +
      ggplot2::theme_minimal()

    pngs[[length(pngs)+1]] <- ggsave_raw(g, glue::glue("Lines_{basis}_with_AE"), out_dir = out_dir)
  }
  pngs
}

# Product-level line chart (paid A v E per product)
plot_paid_ave_per_product <- function(paid_ave_df, out_root = NULL) {
  yrs <- ts_year_cols(paid_ave_df); if (!length(yrs)) return(list())
  out <- list()

  agg <- paid_ave_df %>%
    dplyr::group_by(.data$Peril) %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(as.character(yrs)), ~ sum(.x, na.rm = TRUE)), .groups = "drop")

  d_all <- agg %>%
    dplyr::filter(toupper(.data$Peril) != "TOTAL") %>%
    tidyr::pivot_longer(cols = dplyr::all_of(as.character(yrs)), names_to = "Year", values_to = "AE")

  p_all <- ggplot2::ggplot(d_all, ggplot2::aes(x = as.integer(.data$Year), y = .data$AE, colour = .data$Peril)) +
    ggplot2::geom_line() + ggplot2::geom_point() +
    ggplot2::labs(title = "Paid AvE – All products (perils)", x = "Accident Year", y = "A-E (£m)") +
    ggplot2::theme_minimal()

  out[[length(out)+1]] <- ggsave_raw(p_all, "Paid_AvE_all_products_lines",
                                     out_dir = ensure_dir(fs::path(out_root, "Paid_AvE")))

  for (prod in unique(paid_ave_df$Product)) {
    d <- paid_ave_df %>%
      dplyr::filter(.data$Product == prod, toupper(.data$Peril) != "TOTAL") %>%
      tidyr::pivot_longer(cols = dplyr::all_of(as.character(yrs)), names_to = "Year", values_to = "AE")
    if (!nrow(d)) next

    p <- ggplot2::ggplot(d, ggplot2::aes(x = as.integer(.data$Year), y = .data$AE, colour = .data$Peril)) +
      ggplot2::geom_line() + ggplot2::geom_point() +
      ggplot2::labs(title = paste0("Paid AvE – ", prod, " perils"),
                    x = "Accident Year", y = "A-E (£m)") +
      ggplot2::theme_minimal()

    safe_name <- gsub("[^A-Za-z0-9]+", "_", prod)
    out[[length(out)+1]] <- ggsave_raw(p, paste0("Paid_AvE_", safe_name, "_perils_lines"),
                                       out_dir = fs::path(out_root, "Paid_AvE"))
  }
  out
}
