# R/33_charts_waterfall.R — Waterfall chart functions (cumulative A-E flow)

# Plotly waterfall from A-E deltas (used in server)
waterfall_plot_from_AE <- function(years, deltas, title = "Waterfall",
                                   COL_HEAT_POS = "#d62728", COL_HEAT_NEG = "#2ca02c") {
  if (length(years) != length(deltas) || length(years) == 0) {
    stop("No data for waterfall: years and deltas must have same non-zero length")
  }

  yrs  <- suppressWarnings(as.integer(as.character(years)))
  vals <- suppressWarnings(as.numeric(deltas))
  keep <- !(is.na(yrs) | is.na(vals))
  yrs  <- yrs[keep]; vals <- vals[keep]

  if (length(yrs) == 0) {
    stop("No valid data after cleaning")
  }

  ord  <- order(yrs); yrs <- yrs[ord]; vals <- vals[ord]
  labs <- fmt_year_labels(yrs)  # axis labels YYYY/YY

  plotly::plot_ly(
    type    = "waterfall",
    x       = labs,
    y       = vals,
    measure = rep("relative", length(vals)),
    hovertemplate = "Year %{x}<br>Δ A−E: %{y:.2f}<extra></extra>",
    increasing = list(marker = list(color = COL_HEAT_POS)),
    decreasing = list(marker = list(color = COL_HEAT_NEG)),
    totals     = list(marker = list(color = "#595959")),
    connector  = list(line = list(color = "rgba(0,0,0,0)", width = 0))  # hide connectors
  ) %>%
    plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
}

# ggplot-based waterfall (for compatibility / PNG export)
waterfall_plot_from_AE_gg <- function(years, deltas,
                                      title = "Waterfall",
                                      y_lab = "Δ A−E",
                                      total_color = "#595959",
                                      COL_HEAT_POS = "#d62728",
                                      COL_HEAT_NEG = "#2ca02c") {
  if (length(years) != length(deltas) || length(years) == 0) {
    stop("No data for waterfall: years and deltas must have same non-zero length")
  }

  years <- suppressWarnings(as.integer(as.character(years)))
  deltas <- suppressWarnings(as.numeric(deltas))
  keep <- !(is.na(years) | is.na(deltas))
  years  <- years[keep]
  deltas <- deltas[keep]

  if (length(years) == 0) {
    stop("No valid data after cleaning")
  }

  ord <- order(years)
  years  <- years[ord]
  deltas <- deltas[ord]

  idx     <- seq_along(years)
  running <- cumsum(replace(deltas, is.na(deltas), 0))
  starts  <- c(0, head(running, -1))
  ends    <- starts + deltas

  # Map colours: positive = red, negative = green (same as heatmaps)
  sign_lab <- ifelse(deltas >= 0, "pos", "neg")

  # Axis labels YYYY/YY
  x_labs <- fmt_year_labels(years)

  df <- tibble::tibble(
    Year  = years,
    idx   = idx,
    Start = starts,
    End   = ends,
    Value = deltas,
    Sign  = sign_lab,
    Tooltip = sprintf("Year: %s<br>Δ A−E: %s<br>Cum. start: %s<br>Cum. end: %s",
                      years,
                      scales::number(deltas, accuracy = 0.01),
                      scales::number(starts, accuracy = 0.01),
                      scales::number(ends,   accuracy = 0.01))
  )

  g <- ggplot2::ggplot(df) +
    ggplot2::geom_rect(
      ggplot2::aes(xmin = .data$idx - 0.45, xmax = .data$idx + 0.45,
                   ymin = .data$Start, ymax = .data$End,
                   text = .data$Tooltip, fill = .data$Sign)
    ) +
    ggplot2::scale_fill_manual(values = c(
      pos = COL_HEAT_POS,  # red for positive
      neg = COL_HEAT_NEG   # green for negative
    ), guide = "none") +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous(breaks = idx, labels = x_labs) +
    ggplot2::labs(title = title, x = "Accident Year", y = y_lab) +
    ggplot2::theme_minimal()

  plotly::ggplotly(g, tooltip = "text") %>%
    plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
}

# Static PNG waterfall export
ts_plot_waterfall <- function(total_summary, out_dir = NULL) {
  years <- ts_year_cols(total_summary); if (!length(years)) return(NULL)
  out_dir <- ts_ensure_dir(out_dir)
  pngs <- list()

  for (basis in c("Paid","Incurred")) {
    diff <- ts_slice(total_summary, basis, "A-E")
    vals <- as.numeric(diff)

    if (length(years) != length(vals)) next

    idx     <- seq_along(years)
    running <- cumsum(replace(vals, is.na(vals), 0))
    starts  <- c(0, head(running, -1))
    ends    <- starts + vals

    sign_lab <- ifelse(vals >= 0, "pos", "neg")
    ax <- year_axis(years)

    df <- tibble::tibble(
      Year  = years,
      idx   = idx,
      Start = starts,
      End   = ends,
      Value = vals,
      Sign  = sign_lab
    )

    g <- ggplot2::ggplot(df) +
      ggplot2::geom_rect(ggplot2::aes(
        xmin = .data$idx - 0.45, xmax = .data$idx + 0.45,
        ymin = .data$Start, ymax = .data$End, fill = .data$Sign
      )) +
      ggplot2::scale_fill_manual(values = c(pos = "#d62728", neg = "#2ca02c"), guide = "none") +
      ggplot2::geom_hline(yintercept = 0) +
      ggplot2::scale_x_continuous(breaks = idx, labels = ax$labels) +
      ggplot2::labs(title = glue::glue("{basis} Waterfall (A-E)"),
                    x = "Accident Year", y = "Δ A−E (£m)") +
      ggplot2::theme_minimal()

    pngs[[length(pngs)+1]] <- ggsave_raw(g, glue::glue("Waterfall_{basis}"), out_dir = out_dir)
  }
  pngs
}
