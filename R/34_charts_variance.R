# R/34_charts_variance.R — Variance/bridge chart functions (Expected vs Actual comparison)

# Variance bridge ggplot (Paid vs Incurred, Expected vs Actual)
ts_gg_variance_bridge <- function(total_summary) {
  grand <- function(df, basis, kind) {
    row <- dplyr::filter(df, .data$Basis == basis, .data$`A vs E` == kind)
    if (nrow(row) == 0) return(0.0)
    as.numeric(row$`Grand Total`[1])
  }

  cats     <- c("Paid","Incurred")
  expected <- vapply(cats, function(b) grand(total_summary, b, "Expected"), numeric(1))
  actual   <- vapply(cats, function(b) grand(total_summary, b, "Actual"), numeric(1))
  diff     <- actual - expected

  df <- tibble::tibble(
    Basis = rep(cats, each = 2),
    Type  = rep(c("Expected","Actual"), times = length(cats)),
    Value = c(rbind(expected, actual))
  )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$Basis, y = .data$Value, fill = .data$Type)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.7), width = 0.6) +
    ggplot2::scale_fill_manual(values = c("Expected" = COL_EXPECTED, "Actual" = COL_ACTUAL)) +
    ggplot2::geom_text(
      data = tibble::tibble(
        Basis = cats,
        y     = pmax(expected, actual) * 1.02,
        lbl   = paste0("A-E: ", ts_fmt(diff, 2))
      ),
      ggplot2::aes(x = .data$Basis, y = .data$y, label = .data$lbl),
      inherit.aes = FALSE, vjust = 0
    ) +
    ggplot2::labs(title = "Variance by Basis (Expected vs Actual)",
                  y = "Grand Total (£m)", x = NULL) +
    ggplot2::theme_minimal()
}

# Variance bridge for Plotly (used in server charts)
build_variance_bridge_plotly <- function(total_summary,
                                         COL_ACTUAL = "#1f77b4",
                                         COL_EXPECTED = "#ff7f0e") {
  grand <- function(df, basis, kind) {
    row <- dplyr::filter(df, .data$Basis == basis, .data$`A vs E` == kind)
    if (nrow(row) == 0) return(0.0)
    suppressWarnings(as.numeric(row$`Grand Total`[1])) %||% 0.0
  }

  bases    <- c("Paid","Incurred")
  expected <- vapply(bases, function(b) grand(total_summary, b, "Expected"), numeric(1))
  actual   <- vapply(bases, function(b) grand(total_summary, b, "Actual"),   numeric(1))
  diff     <- actual - expected

  # Build bridge dataframe with spacers
  build_bridge_df <- function(expected, actual) {
    tibble::tibble(
      Basis = c("Paid", "⎯", "Incurred"),
      Exp   = c(expected["Paid"], NA, expected["Incurred"]),
      Act   = c(actual["Paid"],   NA, actual["Incurred"])
    )
  }

  df3 <- build_bridge_df(expected, actual)
  d_act   <- df3 %>% dplyr::select(.data$Basis, Value = .data$Act) %>% dplyr::mutate(Trace = "Actual")
  d_exp   <- df3 %>% dplyr::select(.data$Basis, Value = .data$Exp) %>% dplyr::mutate(Trace = "Expected")
  df_long <- dplyr::bind_rows(d_act, d_exp)

  cats_array <- c("⎯⎯", "Paid", "⎯", "Incurred", "⎯⎯⎯")
  pads <- tibble::tibble(Basis = c("⎯⎯","⎯⎯⎯"), Value = 0, Trace = "Pad")
  df_long2 <- dplyr::bind_rows(df_long, pads)

  plotly::plot_ly() %>%
    plotly::add_bars(
      data = df_long2 %>% dplyr::filter(.data$Trace == "Actual"),
      x = ~Basis, y = ~Value, name = "Actual",
      marker = list(color = COL_ACTUAL),
      hovertemplate = "Basis: %{x}<br>Actual: %{y:.2f}<extra></extra>"
    ) %>%
    plotly::add_bars(
      data = df_long2 %>% dplyr::filter(.data$Trace == "Expected"),
      x = ~Basis, y = ~Value, name = "Expected",
      marker = list(color = COL_EXPECTED),
      hovertemplate = "Basis: %{x}<br>Expected: %{y:.2f}<extra></extra>"
    ) %>%
    plotly::layout(
      barmode = "group",
      xaxis = list(
        categoryorder = "array",
        categoryarray = cats_array,
        title = ""
      ),
      yaxis = list(title = "Grand Total (£m)"),
      title = list(text = "Variance: Expected vs Actual (TOTAL)")
    ) %>%
    plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
}

# Static PNG export for variance bridge
ts_plot_variance_bridge <- function(total_summary, out_dir = NULL) {
  out_dir <- ts_ensure_dir(out_dir)

  grand <- function(df, basis, kind) {
    row <- dplyr::filter(df, .data$Basis == basis, .data$`A vs E` == kind)
    if (nrow(row) == 0) return(0.0)
    as.numeric(row$`Grand Total`[1])
  }

  cats     <- c("Paid","Incurred")
  expected <- vapply(cats, function(b) grand(total_summary, b, "Expected"), numeric(1))
  actual   <- vapply(cats, function(b) grand(total_summary, b, "Actual"), numeric(1))
  diff     <- actual - expected

  df <- tibble::tibble(
    Basis = rep(cats, each = 2),
    Type  = rep(c("Expected","Actual"), times = length(cats)),
    Value = c(rbind(expected, actual))
  )

  g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$Basis, y = .data$Value, fill = .data$Type)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.7), width = 0.6) +
    ggplot2::scale_fill_manual(values = c("Expected" = COL_EXPECTED, "Actual" = COL_ACTUAL)) +
    ggplot2::geom_text(
      data = tibble::tibble(
        Basis = cats,
        y     = pmax(expected, actual) * 1.02,
        lbl   = paste0("A-E: ", ts_fmt(diff, 2))
      ),
      ggplot2::aes(x = .data$Basis, y = .data$y, label = .data$lbl),
      inherit.aes = FALSE, vjust = 0
    ) +
    ggplot2::labs(title = "Variance by Basis", y = "Grand Total (£m)", x = NULL) +
    ggplot2::theme_minimal()

  list(ggsave_raw(g, "Variance_Bridge", out_dir = out_dir))
}

# Cumulative A-E plot (running sum over years)
ts_plot_cumulative_ae <- function(total_summary, basis = c("Paid","Incurred"), out_dir = NULL) {
  basis <- match.arg(basis)
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)

  diff <- ts_slice(total_summary, basis, "A-E")
  vals <- as.numeric(diff)
  cumulative <- cumsum(replace(vals, is.na(vals), 0))

  ax <- year_axis(years)
  df <- tibble::tibble(Year = years, Cumulative = cumulative)

  g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$Year, y = .data$Cumulative)) +
    ggplot2::geom_line(color = "#1f77b4", size = 1) +
    ggplot2::geom_point(color = "#1f77b4", size = 2) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::scale_x_continuous(breaks = ax$breaks, labels = ax$labels) +
    ggplot2::labs(title = glue::glue("{basis} Cumulative A-E"),
                  x = "Accident Year", y = "Cumulative A-E (£m)") +
    ggplot2::theme_minimal()

  list(ggsave_raw(g, glue::glue("Cumulative_{basis}"), out_dir = out_dir))
}
