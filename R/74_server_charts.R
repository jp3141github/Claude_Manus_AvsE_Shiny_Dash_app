# R/74_server_charts.R — Server chart rendering and helpers

register_charts_server <- function(input, output, session, results_obj, chart_data = NULL) {

  # Colours used across heatmaps/waterfalls (same palette as heatmaps)
  COL_HEAT_POS <- get0("COL_HEAT_POS", ifnotfound = "#d62728")  # red (adverse / positive movement)
  COL_HEAT_NEG <- get0("COL_HEAT_NEG", ifnotfound = "#2ca02c")  # green (favourable / negative movement)

  # Reuse your existing formatter for axis
  year_labels <- fmt_year_labels

  .build_bridge_df <- function(expected, actual) {
    tibble::tibble(
      Basis = c("Paid", "⎯", "Incurred"),  # ⎯ acts as a spacer
      Exp   = c(expected["Paid"], NA, expected["Incurred"]),
      Act   = c(actual["Paid"],   NA, actual["Incurred"])
    )
  }

  # Plotly waterfall that your renderers call
  .waterfall_plot_from_AE <- function(years, deltas, title = "Waterfall") {
    validate(need(length(years) == length(deltas) && length(years) > 0,
                  "No data for this selection"))
    yrs  <- suppressWarnings(as.integer(as.character(years)))
    vals <- suppressWarnings(as.numeric(deltas))
    keep <- !(is.na(yrs) | is.na(vals))
    yrs  <- yrs[keep]; vals <- vals[keep]
    validate(need(length(yrs) > 0, "No data for this selection"))

    ord  <- order(yrs); yrs <- yrs[ord]; vals <- vals[ord]
    labs <- year_labels(yrs)  # axis labels only

    plotly::plot_ly(
      type    = "waterfall",
      x       = labs,
      y       = vals,
      measure = rep("relative", length(vals)),
      hovertemplate = "Year %{x}<br>Δ A−E: %{y:.2f}<extra></extra>",
      increasing = list(marker = list(color = COL_HEAT_POS)),
      decreasing = list(marker = list(color = COL_HEAT_NEG)),
      totals     = list(marker = list(color = "#595959")),
      connector  = list(line = list(color = "rgba(0,0,0,0)", width = 0))  # ← hide connectors
    ) %>%
      plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
  }

  # >>> BEGIN PATCH B: WATERFALL HELPER (add in server, before chart renderers) <<<
  .waterfall_plot_from_AE_gg <- function(years, deltas,
                                         title = "Waterfall",
                                         y_lab = "Δ A−E",
                                         total_color = "#595959") {
    validate(need(length(years) == length(deltas) && length(years) > 0,
                  "No data for this selection"))

    years <- suppressWarnings(as.integer(as.character(years)))
    deltas <- suppressWarnings(as.numeric(deltas))
    keep <- !(is.na(years) | is.na(deltas))
    years  <- years[keep]
    deltas <- deltas[keep]

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
    x_labs <- year_labels(years)

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
        aes(xmin = idx - 0.45, xmax = idx + 0.45, ymin = Start, ymax = End,
            text = Tooltip, fill = Sign)
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

  # >>> END PATCH B <<<

  # TOTAL (selection-agnostic) Variance
  output$dyn_ts_variance_bridge_total <- renderPlotly({
    res <- results_obj(); req(res)
    total_summary <- res[["Total Summary"]]
    validate(need(!is.null(total_summary) && nrow(total_summary) > 0, "No data for Total Summary."))

    # Safe getter for the 'Grand Total' by basis/kind
    grand <- function(df, basis, kind) {
      row <- dplyr::filter(df, .data$Basis == basis, .data$`A vs E` == kind)
      if (nrow(row) == 0) return(0.0)
      suppressWarnings(as.numeric(row$`Grand Total`[1])) %||% 0.0
    }

    bases    <- c("Paid","Incurred")  # explicit order
    expected <- vapply(bases, function(b) grand(total_summary, b, "Expected"), numeric(1))
    actual   <- vapply(bases, function(b) grand(total_summary, b, "Actual"),   numeric(1))
    diff     <- actual - expected

    # --- Build with left/right pads for equal whitespace ---
    df3 <- .build_bridge_df(expected, actual)
    d_act   <- df3 %>% dplyr::select(Basis, Value = Act) %>% dplyr::mutate(Trace = "Actual")
    d_exp   <- df3 %>% dplyr::select(Basis, Value = Exp) %>% dplyr::mutate(Trace = "Expected")
    df_long <- dplyr::bind_rows(d_act, d_exp)

    cats_array <- c("⎯⎯", "Paid", "⎯", "Incurred", "⎯⎯⎯")  # pads + spacer
    pads <- tibble::tibble(Basis = c("⎯⎯","⎯⎯⎯"), Value = 0, Trace = "Pad")
    df_long2 <- dplyr::bind_rows(df_long, pads)

    plotly::plot_ly() %>%
      plotly::add_bars(
        data = df_long2 %>% dplyr::filter(Trace == "Actual"),
        x = ~Basis, y = ~Value, name = "Actual",
        marker = list(color = COL_ACTUAL),
        hovertemplate = "Basis: %{x}<br>Actual: %{y:.2f}<extra></extra>"
      ) %>%
      plotly::add_bars(
        data = df_long2 %>% dplyr::filter(Trace == "Expected"),
        x = ~Basis, y = ~Value, name = "Expected",
        marker = list(color = COL_EXPECTED),
        hovertemplate = "Basis: %{x}<br>Expected: %{y:.2f}<extra></extra>"
      ) %>%
      plotly::add_bars(
        data = df_long2 %>% dplyr::filter(Trace == "Pad"),
        x = ~Basis, y = ~Value, name = NULL,
        marker = list(color = "rgba(0,0,0,0)"),
        hoverinfo = "skip", showlegend = FALSE
      ) %>%
      plotly::layout(
        title = list(text = "Variance by Basis (TOTAL)", x = 0, xanchor = "left"),
        barmode = "group",
        bargap = 0.30,
        xaxis = list(
          type = "category",
          categoryorder = "array", categoryarray = cats_array,
          tickvals = c("Paid","⎯","Incurred"), ticktext = c("Paid","⎯","Incurred"),
          automargin = TRUE
        ),
        yaxis = list(title = "Grand Total (£m)"),
        margin = list(t = 56, l = 60, r = 20, b = 50)
      ) %>%
      plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # START OF PATCH C

  # ==========================
  # Product × Year heatmaps (Paid / Incurred) — A→Z top→bottom
  # ==========================
  output$dyn_heatmap_by_product <- renderPlotly({
    res <- results_obj(); req(res)
    pvt <- res[[SHEET_NAMES$paid_ave]]; req(!is.null(pvt), nrow(pvt) > 0)

    # Apply user filters
    prod_sel  <- input$dyn_prod %||% "ALL"
    peril_sel <- input$dyn_peril %||% "ALL"
    seg_group <- input$dyn_segment_group %||% "All"
    excluded  <- input$exclude_products %||% character(0)

    # Filter the pivot table
    d <- pvt %>%
      dplyr::filter(
        toupper(trimws(Peril)) != "TOTAL",
        !Product %in% c("Grand Total","Check"),
        !Product %in% excluded  # Respect exclusions
      )

    # Apply product filter
    if (!identical(prod_sel, "ALL")) {
      d <- d %>% dplyr::filter(Product == prod_sel)
    }

    # Apply peril filter
    if (!identical(peril_sel, "ALL")) {
      d <- d %>% dplyr::filter(Peril == peril_sel)
    }

    # Apply segment filter (if pivot has Segment column)
    if ("Segment (Group)" %in% names(d)) {
      if (identical(seg_group, "NIG")) {
        d <- d %>% dplyr::filter(`Segment (Group)` == "NIG")
      } else if (identical(seg_group, "Non NIG")) {
        d <- d %>% dplyr::filter(`Segment (Group)` == "Non NIG")
      }
    }

    yrs <- ts_year_cols(d); req(length(yrs) > 0)
    d <- d %>%
      tidyr::pivot_longer(all_of(as.character(yrs)), names_to = "Year", values_to = "AE") %>%
      dplyr::mutate(
        Year    = as.integer(Year),
        # A→Z top→bottom in ggplot requires reversed levels (ggplot draws bottom→top)
        Product = factor(Product, levels = rev(sorted_levels_az(Product)))
      )

    g <- ggplot(d, aes(x = Year, y = Product, fill = AE)) +
      geom_tile() +
      scale_y_discrete(drop = FALSE) +
      scale_fill_gradient2(low = COL_HEAT_NEG, mid = "#ffffff", high = COL_HEAT_POS, midpoint = 0) +
      labs(title = "Heatmap – Product × Year (Paid A-E)", x = "Accident Year", y = NULL) +
      theme_minimal()

    ggplotly(g, tooltip = c("x","y","fill"))
  })

  output$dyn_heatmap_by_product_inc <- renderPlotly({
    res <- results_obj(); req(res)
    pvt <- res[[SHEET_NAMES$incurred_ave]]; req(!is.null(pvt), nrow(pvt) > 0)

    # Apply user filters
    prod_sel  <- input$dyn_prod %||% "ALL"
    peril_sel <- input$dyn_peril %||% "ALL"
    seg_group <- input$dyn_segment_group %||% "All"
    excluded  <- input$exclude_products %||% character(0)

    # Filter the pivot table
    d <- pvt %>%
      dplyr::filter(
        toupper(trimws(Peril)) != "TOTAL",
        !Product %in% c("Grand Total","Check"),
        !Product %in% excluded  # Respect exclusions
      )

    # Apply product filter
    if (!identical(prod_sel, "ALL")) {
      d <- d %>% dplyr::filter(Product == prod_sel)
    }

    # Apply peril filter
    if (!identical(peril_sel, "ALL")) {
      d <- d %>% dplyr::filter(Peril == peril_sel)
    }

    # Apply segment filter (if pivot has Segment column)
    if ("Segment (Group)" %in% names(d)) {
      if (identical(seg_group, "NIG")) {
        d <- d %>% dplyr::filter(`Segment (Group)` == "NIG")
      } else if (identical(seg_group, "Non NIG")) {
        d <- d %>% dplyr::filter(`Segment (Group)` == "Non NIG")
      }
    }

    yrs <- ts_year_cols(d); req(length(yrs) > 0)
    d <- d %>%
      tidyr::pivot_longer(all_of(as.character(yrs)), names_to = "Year", values_to = "AE") %>%
      dplyr::mutate(
        Year    = as.integer(Year),
        # A→Z top→bottom
        Product = factor(Product, levels = rev(sorted_levels_az(Product)))
      )

    g <- ggplot(d, aes(x = Year, y = Product, fill = AE)) +
      geom_tile() +
      scale_y_discrete(drop = FALSE) +
      scale_fill_gradient2(low = COL_HEAT_NEG, mid = "#ffffff", high = COL_HEAT_POS, midpoint = 0) +
      labs(title = "Heatmap – Product × Year (Incurred A-E)", x = "Accident Year", y = NULL) +
      theme_minimal()

    ggplotly(g, tooltip = c("x","y","fill"))
  })


  # ==========================
  # Lines – Paid
  # ==========================
  output$dyn_ts_lines_paid <- renderPlotly({
    res <- results_obj(); req(res)
    sp <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Paid",
      seg_group = input$dyn_segment_group
    )
    validate(need(length(sp$years) > 0, "No data for this selection"))

    # Store data for CSV download
    if (!is.null(chart_data)) {
      chart_data[["dyn_ts_lines_paid"]] <- tibble::tibble(
        Year = sp$years,
        Actual = sp$Actual,
        Expected = sp$Expected,
        AE_Delta = sp$AE
      )
    }

    df_line <- tibble(Year = sp$years, Actual = sp$Actual, Expected = sp$Expected) |>
      tidyr::pivot_longer(c("Actual","Expected"), names_to = "Series", values_to = "Value")
    df_bar  <- tibble(Year = sp$years, AE = sp$AE)

    ax <- year_axis(sp$years)

    g <- ggplot() +
      geom_col(data = df_bar, aes(x = Year, y = AE), alpha = 0.35) +
      geom_line(data = df_line, aes(x = Year, y = Value, linetype = Series, colour = Series)) +
      geom_point(data = df_line, aes(x = Year, y = Value, colour = Series)) +
      scale_linetype_manual(values = c("Actual" = "solid", "Expected" = "dotted")) +
      scale_color_manual(values = c("Actual" = COL_ACTUAL, "Expected" = COL_EXPECTED)) +
      scale_x_continuous(breaks = ax$breaks, labels = ax$labels) +
      labs(title = "Paid: Actual vs Expected with A-E",
           x = "Accident Year", y = "Actual / Expected (£m)") +
      theme_minimal() + theme(panel.grid.minor = element_blank())

    ggplotly(g, tooltip = c("x","y","colour")) %>%
      layout(hovermode = "x unified") %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # ==========================
  # Lines – Incurred
  # ==========================
  output$dyn_ts_lines_incurred <- renderPlotly({
    res <- results_obj(); req(res)
    sp <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Incurred",
      seg_group = input$dyn_segment_group
    )
    validate(need(length(sp$years) > 0, "No data for this selection"))

    # Store data for CSV download
    if (!is.null(chart_data)) {
      chart_data[["dyn_ts_lines_incurred"]] <- tibble::tibble(
        Year = sp$years,
        Actual = sp$Actual,
        Expected = sp$Expected,
        AE_Delta = sp$AE
      )
    }

    df_line <- tibble(Year = sp$years, Actual = sp$Actual, Expected = sp$Expected) |>
      tidyr::pivot_longer(c("Actual","Expected"), names_to = "Series", values_to = "Value")
    df_bar  <- tibble(Year = sp$years, AE = sp$AE)

    ax <- year_axis(sp$years)

    g <- ggplot() +
      geom_col(data = df_bar, aes(x = Year, y = AE), alpha = 0.35) +
      geom_line(data = df_line, aes(x = Year, y = Value, linetype = Series, colour = Series)) +
      geom_point(data = df_line, aes(x = Year, y = Value, colour = Series)) +
      scale_linetype_manual(values = c("Actual" = "solid", "Expected" = "dotted")) +
      scale_color_manual(values = c("Actual" = COL_ACTUAL, "Expected" = COL_EXPECTED)) +
      scale_x_continuous(breaks = ax$breaks, labels = ax$labels) +
      labs(title = "Incurred: Actual vs Expected with A-E",
           x = "Accident Year", y = "Actual / Expected (£m)") +
      theme_minimal() + theme(panel.grid.minor = element_blank())

    ggplotly(g, tooltip = c("x","y","colour")) %>%
      layout(hovermode = "x unified") %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # ==========================
  # Heatmap – Paid
  # ==========================

  # ---- CHM-FIX 4 (in-server) : Paid heatmap using build_heatmap_px ----
  output$dyn_ts_heatmap_paid <- plotly::renderPlotly({
    res <- results_obj(); req(res)

    # Apply user filters
    prod_sel  <- input$dyn_prod %||% "ALL"
    peril_sel <- input$dyn_peril %||% "ALL"
    seg_group <- input$dyn_segment_group %||% "All"
    excluded  <- input$exclude_products %||% character(0)

    # Get pivot and apply filters
    pvt <- get_table_by(res, basis = "Paid", kind = "AE", seg_group = seg_group)
    if (is.null(pvt) || !nrow(pvt)) validate(need(FALSE, "No data for Paid AvE"))

    # Apply filters using pp_filter
    pvt_filtered <- pp_filter(pvt, prod_sel, peril_sel)

    # Further filter by exclusions
    if (length(excluded)) {
      pvt_filtered <- pvt_filtered %>% dplyr::filter(!Product %in% excluded)
    }

    # Filter out Grand Total and Check
    pvt_filtered <- pvt_filtered %>%
      dplyr::filter(!Product %in% c("Grand Total","Check"))

    if (!nrow(pvt_filtered)) validate(need(FALSE, "No data for this selection"))

    # Get year columns and convert to long format
    yrs <- ts_year_cols(pvt_filtered)
    req(length(yrs) > 0)

    d <- pvt_filtered %>%
      tidyr::pivot_longer(all_of(as.character(yrs)), names_to = "accidentyear", values_to = "AE_value") %>%
      dplyr::mutate(accidentyear = as.integer(accidentyear)) %>%
      dplyr::select(Product, accidentyear, AE_value)

    # Build heatmap with filtered data
    build_heatmap_px(
      d,
      product_col   = "Product",
      year_col      = "accidentyear",
      value_col     = "AE_value",
      title         = "Heatmap – Product × Year (Paid A-E)",
      palette       = "RdBu",
      zmid          = 0,
      agg_fn        = sum,
      na_rm         = TRUE
    )
  })

  # ==========================
  # Heatmap – Incurred
  # ==========================

  output$dyn_ts_heatmap_incurred <- plotly::renderPlotly({
    res <- results_obj(); req(res)

    # Apply user filters
    prod_sel  <- input$dyn_prod %||% "ALL"
    peril_sel <- input$dyn_peril %||% "ALL"
    seg_group <- input$dyn_segment_group %||% "All"
    excluded  <- input$exclude_products %||% character(0)

    # Get pivot and apply filters
    pvt <- get_table_by(res, basis = "Incurred", kind = "AE", seg_group = seg_group)
    if (is.null(pvt) || !nrow(pvt)) validate(need(FALSE, "No data for Incurred AvE"))

    # Apply filters using pp_filter
    pvt_filtered <- pp_filter(pvt, prod_sel, peril_sel)

    # Further filter by exclusions
    if (length(excluded)) {
      pvt_filtered <- pvt_filtered %>% dplyr::filter(!Product %in% excluded)
    }

    # Filter out Grand Total and Check
    pvt_filtered <- pvt_filtered %>%
      dplyr::filter(!Product %in% c("Grand Total","Check"))

    if (!nrow(pvt_filtered)) validate(need(FALSE, "No data for this selection"))

    # Get year columns and convert to long format
    yrs <- ts_year_cols(pvt_filtered)
    req(length(yrs) > 0)

    d <- pvt_filtered %>%
      tidyr::pivot_longer(all_of(as.character(yrs)), names_to = "accidentyear", values_to = "AE_value") %>%
      dplyr::mutate(accidentyear = as.integer(accidentyear)) %>%
      dplyr::select(Product, accidentyear, AE_value)

    # Build heatmap with filtered data
    build_heatmap_px(
      d,
      product_col   = "Product",
      year_col      = "accidentyear",
      value_col     = "AE_value",
      title         = "Heatmap – Product × Year (Incurred A-E)",
      palette       = "RdBu",
      zmid          = 0,
      agg_fn        = sum,
      na_rm         = TRUE
    )
  })

  # ==========================
  # Combined Heatmap – Paid & Incurred
  # ==========================
  output$dyn_ts_heatmap_ae <- renderPlotly({
    res <- results_obj(); req(res)
    spP <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Paid",
      seg_group = input$dyn_segment_group
    )
    spI <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Incurred",
      seg_group = input$dyn_segment_group
    )
    years <- sort(unique(c(spP$years, spI$years)))
    validate(need(length(years) > 0, "No data for this selection"))

    ax <- year_axis(years)

    df <- dplyr::bind_rows(
      tibble(Basis = "Paid",     Year = years, AE = align_series(spP$years, spP$AE, years)),
      tibble(Basis = "Incurred", Year = years, AE = align_series(spI$years, spI$AE, years))
    )

    g <- ggplot(df, aes(x = factor(Year, levels = ax$breaks, labels = ax$labels),
                        y = Basis, fill = AE)) +
      geom_tile() +
      scale_fill_gradient2(low = COL_HEAT_NEG, mid = "#ffffff", high = COL_HEAT_POS, midpoint = 0) +
      labs(title = "A-E Heatmap (Paid & Incurred, selection)", x = NULL, y = NULL) +
      scale_x_discrete(drop = FALSE) +
      theme_minimal()

    ggplotly(g, tooltip = c("x","y","fill")) %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # ==========================
  # Variance Bridge (Selection)
  # ==========================
  output$dyn_ts_variance_bridge <- renderPlotly({
    res <- results_obj(); req(res)

    # --- helper: GT getter from Total Summary
    total_summary <- res[["Total Summary"]]
    grand <- function(df, basis, kind) {
      row <- dplyr::filter(df, .data$Basis == basis, .data$`A vs E` == kind)
      if (nrow(row) == 0) return(0.0)
      suppressWarnings(as.numeric(row$`Grand Total`[1])) %||% 0.0
    }

    prod_sel  <- input$dyn_prod          %||% "ALL"
    peril_sel <- input$dyn_peril         %||% "ALL"
    seg_grp   <- input$dyn_segment_group %||% "All"

    # --- CASE 1: All dropdowns at defaults -> mirror Total Summary EXACTLY
    if (identical(prod_sel, "ALL") && identical(peril_sel, "ALL") && identical(seg_grp, "All")) {
      validate(need(!is.null(total_summary) && nrow(total_summary) > 0, "No data for Total Summary."))
      expected <- c(Paid     = grand(total_summary, "Paid",     "Expected"),
                    Incurred = grand(total_summary, "Incurred", "Expected"))
      actual   <- c(Paid     = grand(total_summary, "Paid",     "Actual"),
                    Incurred = grand(total_summary, "Incurred", "Actual"))

      df3 <- tibble::tibble(
        Basis = c("Paid","⎯","Incurred"),
        Exp   = c(expected["Paid"], NA, expected["Incurred"]),
        Act   = c(actual["Paid"],   NA, actual["Incurred"])
      )
      d_act   <- df3 %>% dplyr::select(Basis, Value = Act) %>% dplyr::mutate(Trace = "Actual")
      d_exp   <- df3 %>% dplyr::select(Basis, Value = Exp) %>% dplyr::mutate(Trace = "Expected")
      df_long <- dplyr::bind_rows(d_act, d_exp)

      cats <- c("⎯⎯","Paid","⎯","Incurred","⎯⎯⎯")
      pads <- tibble::tibble(Basis = c("⎯⎯","⎯⎯⎯"), Value = 0, Trace = "Pad")
      df_long2 <- dplyr::bind_rows(df_long, pads)

      return(
        plotly::plot_ly() %>%
          plotly::add_bars(
            data = df_long2 %>% dplyr::filter(Trace == "Actual"),
            x = ~Basis, y = ~Value, name = "Actual",
            marker = list(color = COL_ACTUAL),
            hovertemplate = "Basis: %{x}<br>Actual: %{y:.2f}<extra></extra>"
          ) %>%
          plotly::add_bars(
            data = df_long2 %>% dplyr::filter(Trace == "Expected"),
            x = ~Basis, y = ~Value, name = "Expected",
            marker = list(color = COL_EXPECTED),
            hovertemplate = "Basis: %{x}<br>Expected: %{y:.2f}<extra></extra>"
          ) %>%
          plotly::add_bars(
            data = df_long2 %>% dplyr::filter(Trace == "Pad"),
            x = ~Basis, y = ~Value, name = NULL,
            marker = list(color = "rgba(0,0,0,0)"),
            hoverinfo = "skip", showlegend = FALSE
          ) %>%
          plotly::layout(
            title = list(text = "Variance by Basis (Selection)", x = 0, xanchor = "left"),
            barmode = "group",
            bargap = 0.30,
            xaxis = list(
              type = "category",
              categoryorder = "array", categoryarray = cats,
              tickvals = c("Paid","⎯","Incurred"), ticktext = c("Paid","⎯","Incurred"),
              automargin = TRUE
            ),
            yaxis = list(title = "Grand Total (£m)")
          ) %>%
          plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
      )
    }

    # --- CASE 2: Any selection applied -> recompute from RAW with your same filters
    raw <- res[[SHEET_NAMES$raw]] %||% res[["A v E MRG Actuals Expecteds"]]
    validate(need(!is.null(raw) && nrow(raw) > 0, "RAW table missing"))

    # apply the same MT / ProjectionDate / Event filters used in build_all_tables()
    df <- coerce_types(raw)
    df <- apply_filters(
      df,
      model_type      = input$model_type,
      projection_date = suppressWarnings(lubridate::ymd(input$projection_date)),
      event_type      = input$event_type
    )
    validate(need(nrow(df) > 0, "No data after model/date/event filters"))

    # apply dropdowns
    if (!identical(prod_sel, "ALL"))  df <- df %>% dplyr::filter(Product == prod_sel)

    if (!identical(peril_sel, "ALL")) {
      df <- df %>% dplyr::filter(Peril == peril_sel)
    } else {
      # ALL perils: exclude the roll-up TOTAL to avoid double counting
      df <- df %>% dplyr::filter(toupper(trimws(Peril)) != "TOTAL")
    }

    if (identical(seg_grp, "NIG")) {
      df <- df %>% dplyr::filter(Segment == "NIG")
    } else if (identical(seg_grp, "Non NIG")) {
      df <- df %>% dplyr::filter(Segment != "NIG" | is.na(Segment))
    }

    validate(need(nrow(df) > 0, "No rows match Product/Peril/Segment selection"))

    # aggregate to GT in £m
    agg <- df %>%
      dplyr::filter(Measure %in% c("Paid","Incurred")) %>%
      dplyr::group_by(Measure) %>%
      dplyr::summarise(
        Expected = sum(Expected, na.rm = TRUE)/1e6,
        Actual   = sum(Actual,   na.rm = TRUE)/1e6,
        .groups = "drop"
      )

    expected <- c(
      Paid     = agg$Expected[agg$Measure == "Paid"]     %||% 0,
      Incurred = agg$Expected[agg$Measure == "Incurred"] %||% 0
    )
    actual <- c(
      Paid     = agg$Actual[agg$Measure == "Paid"]       %||% 0,
      Incurred = agg$Actual[agg$Measure == "Incurred"]   %||% 0
    )

    # build chart (same framing as TOTAL)
    df3 <- tibble::tibble(
      Basis = c("Paid","⎯","Incurred"),
      Exp   = c(expected["Paid"], NA, expected["Incurred"]),
      Act   = c(actual["Paid"],   NA, actual["Incurred"])
    )
    d_act   <- df3 %>% dplyr::select(Basis, Value = Act) %>% dplyr::mutate(Trace = "Actual")
    d_exp   <- df3 %>% dplyr::select(Basis, Value = Exp) %>% dplyr::mutate(Trace = "Expected")
    df_long <- dplyr::bind_rows(d_act, d_exp)

    cats <- c("⎯⎯","Paid","⎯","Incurred","⎯⎯⎯")
    pads <- tibble::tibble(Basis = c("⎯⎯","⎯⎯⎯"), Value = 0, Trace = "Pad")
    df_long2 <- dplyr::bind_rows(df_long, pads)

    plotly::plot_ly() %>%
      plotly::add_bars(
        data = df_long2 %>% dplyr::filter(Trace == "Actual"),
        x = ~Basis, y = ~Value, name = "Actual",
        marker = list(color = COL_ACTUAL),
        hovertemplate = "Basis: %{x}<br>Actual: %{y:.2f}<extra></extra>"
      ) %>%
      plotly::add_bars(
        data = df_long2 %>% dplyr::filter(Trace == "Expected"),
        x = ~Basis, y = ~Value, name = "Expected",
        marker = list(color = COL_EXPECTED),
        hovertemplate = "Basis: %{x}<br>Expected: %{y:.2f}<extra></extra>"
      ) %>%
      plotly::add_bars(
        data = df_long2 %>% dplyr::filter(Trace == "Pad"),
        x = ~Basis, y = ~Value, name = NULL,
        marker = list(color = "rgba(0,0,0,0)"),
        hoverinfo = "skip", showlegend = FALSE
      ) %>%
      plotly::layout(
        title = list(text = "Variance by Basis (Selection)", x = 0, xanchor = "left"),
        barmode = "group",
        bargap = 0.30,
        xaxis = list(
          type = "category",
          categoryorder = "array", categoryarray = cats,
          tickvals = c("Paid","⎯","Incurred"), ticktext = c("Paid","⎯","Incurred"),
          automargin = TRUE
        ),
        yaxis = list(title = "Grand Total (£m)")
      ) %>%
      plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # ==========================
  # Waterfall – Paid
  # ==========================
  output$dyn_ts_waterfall_paid <- renderPlotly({
    res <- results_obj(); req(res)
    sp <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Paid",
      seg_group = input$dyn_segment_group
    )
    validate(need(length(sp$years) > 0, "No data for this selection"))

    # Store data for CSV download
    if (!is.null(chart_data)) {
      chart_data[["dyn_ts_waterfall_paid"]] <- tibble::tibble(
        Year = sp$years,
        Actual = sp$Actual,
        Expected = sp$Expected,
        AE_Delta = sp$AE
      )
    }

    .waterfall_plot_from_AE(sp$years, sp$AE, "Paid: A-E Waterfall by Accident Year")
  })

  # ==========================
  # Waterfall – Incurred
  # ==========================
  output$dyn_ts_waterfall_incurred <- renderPlotly({
    res <- results_obj(); req(res)
    sp <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Incurred",
      seg_group = input$dyn_segment_group
    )
    validate(need(length(sp$years) > 0, "No data for this selection"))

    # Store data for CSV download
    if (!is.null(chart_data)) {
      chart_data[["dyn_ts_waterfall_incurred"]] <- tibble::tibble(
        Year = sp$years,
        Actual = sp$Actual,
        Expected = sp$Expected,
        AE_Delta = sp$AE
      )
    }

    .waterfall_plot_from_AE(sp$years, sp$AE, "Incurred: A-E Waterfall by Accident Year")
  })

  # ==========================
  # Cumulative – Paid
  # ==========================
  output$dyn_ts_cum_paid <- renderPlotly({
    res <- results_obj(); req(res)
    sp <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Paid",
      seg_group = input$dyn_segment_group
    )
    validate(need(length(sp$years) > 0, "No data for this selection"))

    df <- tibble(
      Year = as.integer(sp$years),
      `Actual (agg)`   = cumsum(replace(sp$Actual,   is.na(sp$Actual),   0)),
      `Expected (agg)` = cumsum(replace(sp$Expected, is.na(sp$Expected), 0))
    ) |>
      tidyr::pivot_longer(-Year, names_to = "Series", values_to = "Value")

    ax <- year_axis(sp$years)

    g <- ggplot(df, aes(x = Year, y = Value, linetype = Series, colour = Series)) +
      geom_line() + geom_point() +
      scale_linetype_manual(values = c("Actual (agg)" = "solid", "Expected (agg)" = "dotted")) +
      scale_color_manual(values = c("Actual (agg)" = COL_ACTUAL, "Expected (agg)" = COL_EXPECTED)) +
      scale_x_continuous(breaks = ax$breaks, labels = ax$labels) +
      labs(title = "Paid: Cumulative Actual vs Expected",
           x = "Accident Year", y = "Cumulative (£m)") +
      theme_minimal()

    ggplotly(g, tooltip = c("x","y","colour")) %>%
      layout(hovermode = "x unified") %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # ==========================
  # Cumulative – Incurred
  # ==========================
  output$dyn_ts_cum_incurred <- renderPlotly({
    res <- results_obj(); req(res)
    sp <- series_pack(
      res, input$dyn_prod, input$dyn_peril,
      basis = "Incurred",
      seg_group = input$dyn_segment_group
    )
    validate(need(length(sp$years) > 0, "No data for this selection"))

    df <- tibble(
      Year = as.integer(sp$years),
      `Actual (agg)`   = cumsum(replace(sp$Actual,   is.na(sp$Actual),   0)),
      `Expected (agg)` = cumsum(replace(sp$Expected, is.na(sp$Expected), 0))
    ) |>
      tidyr::pivot_longer(-Year, names_to = "Series", values_to = "Value")

    ax <- year_axis(sp$years)

    g <- ggplot(df, aes(x = Year, y = Value, linetype = Series, colour = Series)) +
      geom_line() + geom_point() +
      scale_linetype_manual(values = c("Actual (agg)" = "solid", "Expected (agg)" = "dotted")) +
      scale_color_manual(values = c("Actual (agg)" = COL_ACTUAL, "Expected (agg)" = COL_EXPECTED)) +
      scale_x_continuous(breaks = ax$breaks, labels = ax$labels) +
      labs(title = "Incurred: Cumulative Actual vs Expected",
           x = "Accident Year", y = "Cumulative (£m)") +
      theme_minimal()

    ggplotly(g, tooltip = c("x","y","colour")) %>%
      layout(hovermode = "x unified") %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # >>> END PATCH C <<<

  # ---- Chart A: 2 lines (Paid AvE light blue, Incurred AvE purple) across years
  output$dyn_chart_A <- renderPlotly({
    res <- results_obj(); req(res)
    spP <- series_pack(res, input$dyn_prod, input$dyn_peril, basis = "Paid",
                       seg_group = input$dyn_segment_group)
    spI <- series_pack(res, input$dyn_prod, input$dyn_peril, basis = "Incurred",
                       seg_group = input$dyn_segment_group)
    years <- sort(unique(c(spP$years, spI$years))); validate(need(length(years) > 0, "No data"))
    ax <- year_axis(years)

    d <- dplyr::bind_rows(
      tibble::tibble(Year = years, AvE = align_series(spP$years, spP$AE, years), Trace = "Paid AvE"),
      tibble::tibble(Year = years, AvE = align_series(spI$years, spI$AE, years), Trace = "Incurred AvE")
    )

    plotly::plot_ly(
      d, x = ~Year, y = ~AvE, color = ~Trace,
      colors = c("Paid AvE" = "#67B8FF", "Incurred AvE" = "#7B2CBF")
    ) %>%
      plotly::add_lines() %>%
      plotly::layout(
        xaxis = list(title = "Year", tickmode = "array", tickvals = ax$breaks, ticktext = ax$labels),
        yaxis = list(title = "AvE (A − E)"),
        legend = list(orientation = "h", x = 0, y = 1.1),
        hovermode = "x unified"
      )
  })

  # ---- Chart B: Prior years (exclude current), Product × SegmentGroup lines
  output$dyn_chart_B <- renderPlotly({
    res <- results_obj(); req(res)
    raw <- res[[SHEET_NAMES$raw]] %||% res[["A v E MRG Actuals Expecteds"]]
    validate(need(!is.null(raw) && nrow(raw) > 0, "RAW table missing"))

    d <- coerce_types(raw) %>%
      dplyr::filter(!is.na(Measure) & Measure %in% c("Paid","Incurred")) %>%
      dplyr::mutate(
        `Accident Year` = suppressWarnings(as.integer(`Accident Year`)),
        SegmentGroup    = dplyr::if_else(Segment == "NIG", "NIG", "exNIG"),  # rename Non NIG -> exNIG
        AE              = as.numeric(`A - E`)
      ) %>%
      # drop bad rows
      dplyr::filter(!is.na(`Accident Year`),
                    !(Product %in% c(0, "0")),
                    !is.na(SegmentGroup),
                    nzchar(Product))

    validate(need(nrow(d) > 0, "No data after cleaning"))

    # prior years only
    cy <- max(d$`Accident Year`, na.rm = TRUE)
    d  <- d %>% dplyr::filter(`Accident Year` < cy)
    validate(need(nrow(d) > 0, "No prior-year rows in RAW"))

    # aggregate A−E to Product × SegmentGroup × Measure
    agg <- d %>%
      dplyr::group_by(Product, SegmentGroup, Measure) %>%
      dplyr::summarise(AvE_m = sum(AE, na.rm = TRUE) / 1e6, .groups = "drop") %>%
      dplyr::mutate(
        # build axis labels as "Product – SegmentGroup" (no word 'combo' anywhere)
        XLabel  = paste(Product, "–", SegmentGroup),
        Product = factor(Product, levels = sorted_levels_az(Product))
      )

    validate(need(nrow(agg) > 0, "Nothing to plot"))

    # order: Product A→Z, then SegmentGroup (NIG, exNIG)
    seg_order <- c("NIG", "exNIG")
    x_levels <- agg %>%
      dplyr::arrange(Product, factor(SegmentGroup, levels = seg_order)) %>%
      dplyr::pull(XLabel) %>% unique()

    cols <- c("Paid" = "#67B8FF", "Incurred" = "#7B2CBF")

    plotly::plot_ly(
      agg %>% dplyr::mutate(XLabel = factor(XLabel, levels = x_levels)),
      x = ~as.character(XLabel),    # ensure categoryarray applies
      y = ~AvE_m,
      color = ~Measure, colors = cols,
      type = "scatter", mode = "lines+markers"
    ) %>%
      plotly::layout(
        title = list(text = "Prior years — by Product and Segment Group", x = 0, xanchor = "left"),
        xaxis = list(
          title = list(text = ""),
          type = "category",
          categoryorder = "array", categoryarray = x_levels,
          tickangle = 45, automargin = TRUE
        ),
        yaxis = list(title = "A − E (£m)"),
        legend = list(orientation = "h", x = 0, xanchor = "left", y = -0.24, yanchor = "top"),
        showlegend = TRUE,                       # <<< ensure legend visible
        margin = list(t = 56, l = 60, r = 20, b = 120),
        hovermode = "x unified"
      ) %>%
      plotly::config(displayModeBar = TRUE, displaylogo = FALSE)
  })

  # >>> BEGIN PATCH D: CHARTS UI BUILDER (replace existing output$charts_ui or add new) <<<
  output$charts_ui <- renderUI({
    res <- results_obj(); if (is.null(res)) return(p("No charts yet. Run analysis first."))

    tagList(
      # Row 1: TWO 6-wide Variances (TOTAL vs Selection)
      fluidRow(
        column(6, exp_card("Variance (TOTAL)", "dyn_ts_variance_bridge_total", height = "300px")),
        column(6, exp_card("Variance (Selection)", "dyn_ts_variance_bridge", height = "300px"))
      ),

      br(),

      # Row: Chart A / Chart B
      fluidRow(
        column(
          6,
          exp_card("Chart A — AvE lines (Paid vs Incurred)", "dyn_chart_A", height = "300px")
        ),
        column(
          6,
          exp_card("Chart B — Prior years, by Segment Group", "dyn_chart_B", height = "300px")
        )
      ),

      br(),

      # Row 2: Lines – Paid / Incurred
      fluidRow(
        column(6, exp_card("Lines – Paid",     "dyn_ts_lines_paid",     height = "300px")),
        column(6, exp_card("Lines – Incurred", "dyn_ts_lines_incurred", height = "300px"))
      ),

      br(),

      # Combined heatmap (Paid + Incurred)
      fluidRow(
        column(12, exp_card("Heatmap – Paid & Incurred (A-E)", "dyn_ts_heatmap_ae", height = "320px"))
      ),

      br(),

      # Row: Heatmaps – Paid / Incurred (selection-aware: ALL vs specific product behavior)
      fluidRow(
        column(6, exp_card("Heatmap – Paid (A-E)",     "dyn_ts_heatmap_paid",     height = "300px")),
        column(6, exp_card("Heatmap – Incurred (A-E)", "dyn_ts_heatmap_incurred", height = "300px"))
      ),

      br(),

      # Product × Year heatmaps
      fluidRow(
        column(6, exp_card("Heatmap – Product × Year (Paid A-E)",     "dyn_heatmap_by_product",     height = "360px")),
        column(6, exp_card("Heatmap – Product × Year (Incurred A-E)", "dyn_heatmap_by_product_inc", height = "360px"))
      ),

      br(),

      # Waterfalls – Paid / Incurred
      fluidRow(
        column(6, exp_card("Waterfall – Paid",     "dyn_ts_waterfall_paid",     height = "300px")),
        column(6, exp_card("Waterfall – Incurred", "dyn_ts_waterfall_incurred", height = "300px"))
      ),

      br(),

      # Cumulative – Paid / Incurred
      fluidRow(
        column(6, exp_card("Cumulative – Paid",     "dyn_ts_cum_paid",     height = "300px")),
        column(6, exp_card("Cumulative – Incurred", "dyn_ts_cum_incurred", height = "300px"))
      )
    )
  })
  # >>> END PATCH D <<<

}
