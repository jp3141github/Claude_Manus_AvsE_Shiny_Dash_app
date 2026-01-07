# R/76_server_validation.R — Validation summary tab implementation

register_validation_server <- function(input, output, session, uploaded_df, results_obj) {

  # Main Checks UI
  output$checks_ui <- renderUI({
    df <- uploaded_df()
    if (is.null(df) || nrow(df) == 0) {
      return(
        div(
          class = "p-4 text-center",
          h4("📋 Data Validation"),
          p("Upload a CSV/Excel file to see validation summary.", class = "text-muted mt-3")
        )
      )
    }

    tagList(
      fluidRow(
        column(6, card(
          card_header("✓ Column Validation"),
          DTOutput("check_columns_table")
        )),
        column(6, card(
          card_header("📊 Data Summary"),
          tableOutput("check_summary_table")
        ))
      ),
      fluidRow(
        column(12, card(
          card_header("⚠️ Quality Warnings"),
          uiOutput("check_warnings_ui")
        ))
      ),
      fluidRow(
        column(6, card(
          card_header("📅 Year Coverage"),
          plotly::plotlyOutput("check_year_timeline", height = "200px")
        )),
        column(6, card(
          card_header("🎯 Data Completeness Score"),
          uiOutput("check_completeness_score")
        ))
      )
    )
  })

  # Column validation table
  output$check_columns_table <- renderDT({
    df <- uploaded_df()
    req(!is.null(df), nrow(df) > 0)

    expected <- EXPECTED_COLUMNS
    found <- names(df)

    validation_df <- data.frame(
      Column = expected,
      Status = ifelse(expected %in% found, "✓", "✗"),
      Found = ifelse(expected %in% found, "Yes", "Missing"),
      stringsAsFactors = FALSE
    )

    # Add extra columns not expected
    extra <- setdiff(found, expected)
    if (length(extra)) {
      extra_df <- data.frame(
        Column = extra,
        Status = "➕",
        Found = "Extra",
        stringsAsFactors = FALSE
      )
      validation_df <- rbind(validation_df, extra_df)
    }

    DT::datatable(
      validation_df,
      options = list(
        pageLength = 20,
        dom = 't',  # No search, just table
        ordering = FALSE
      ),
      rownames = FALSE,
      escape = FALSE
    ) %>%
      DT::formatStyle(
        'Status',
        target = 'row',
        backgroundColor = DT::styleEqual(
          c("✓", "✗", "➕"),
          c("#d4edda", "#f8d7da", "#fff3cd")
        )
      )
  })

  # Data summary table
  output$check_summary_table <- renderTable({
    df <- uploaded_df()
    req(!is.null(df), nrow(df) > 0)

    # Calculate summary stats
    total_rows <- nrow(df)

    # Products and Perils
    n_products <- if ("Product" %in% names(df)) {
      length(unique(df$Product[!is.na(df$Product) & df$Product != ""]))
    } else 0

    n_perils <- if ("Peril" %in% names(df)) {
      length(unique(df$Peril[!is.na(df$Peril) & df$Peril != ""]))
    } else 0

    # Year range
    year_range <- if ("Accident Year" %in% names(df)) {
      years <- suppressWarnings(as.integer(df$`Accident Year`))
      years <- years[!is.na(years)]
      if (length(years) > 0) {
        paste(min(years), "–", max(years))
      } else "No valid years"
    } else "Column missing"

    # Measures
    measures <- if ("Measure" %in% names(df) || "ObjectName" %in% names(df)) {
      if ("Measure" %in% names(df)) {
        paste(unique(na.omit(df$Measure)), collapse = ", ")
      } else {
        "Derived from ObjectName"
      }
    } else "Not available"

    # Projection dates
    n_proj_dates <- if ("ProjectionDate" %in% names(df)) {
      length(unique(df$ProjectionDate[!is.na(df$ProjectionDate)]))
    } else 0

    data.frame(
      Metric = c(
        "Total Rows",
        "Unique Products",
        "Unique Perils",
        "Year Range",
        "Measures",
        "Projection Dates"
      ),
      Value = c(
        format(total_rows, big.mark = ","),
        as.character(n_products),
        as.character(n_perils),
        year_range,
        measures,
        as.character(n_proj_dates)
      ),
      stringsAsFactors = FALSE
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE, width = "100%")

  # Quality warnings
  output$check_warnings_ui <- renderUI({
    df <- uploaded_df()
    req(!is.null(df), nrow(df) > 0)

    warnings <- list()

    # Check for missing required columns
    missing_cols <- setdiff(EXPECTED_COLUMNS, names(df))
    if (length(missing_cols)) {
      warnings <- c(warnings, list(
        div(class = "alert alert-danger", role = "alert",
            strong("Missing columns: "), paste(missing_cols, collapse = ", "))
      ))
    }

    # Check for rows with missing Actual or Expected
    if (all(c("Actual", "Expected") %in% names(df))) {
      missing_actual <- sum(is.na(df$Actual))
      missing_expected <- sum(is.na(df$Expected))

      if (missing_actual > 0) {
        pct <- round(missing_actual / nrow(df) * 100, 1)
        warnings <- c(warnings, list(
          div(class = "alert alert-warning", role = "alert",
              sprintf("⚠️ %s rows (%.1f%%) have missing Actual values",
                     format(missing_actual, big.mark = ","), pct))
        ))
      }

      if (missing_expected > 0) {
        pct <- round(missing_expected / nrow(df) * 100, 1)
        warnings <- c(warnings, list(
          div(class = "alert alert-warning", role = "alert",
              sprintf("⚠️ %s rows (%.1f%%) have missing Expected values",
                     format(missing_expected, big.mark = ","), pct))
        ))
      }
    }

    # Check for potential duplicates
    if (all(c("Product", "Peril", "Accident Year", "ProjectionDate", "Measure") %in% names(df))) {
      key_cols <- c("Product", "Peril", "Accident Year", "ProjectionDate", "Measure")
      dupes <- df %>%
        dplyr::group_by(dplyr::across(dplyr::all_of(key_cols))) %>%
        dplyr::filter(dplyr::n() > 1) %>%
        dplyr::ungroup()

      if (nrow(dupes) > 0) {
        warnings <- c(warnings, list(
          div(class = "alert alert-warning", role = "alert",
              sprintf("⚠️ Found %s potential duplicate rows (same Product/Peril/Year/Date/Measure)",
                     format(nrow(dupes), big.mark = ",")))
        ))
      }
    }

    # Check for years outside expected range
    if ("Accident Year" %in% names(df)) {
      years <- suppressWarnings(as.integer(df$`Accident Year`))
      out_of_range <- sum(years < YEAR_MIN_DEFAULT | years > YEAR_MAX_DEFAULT, na.rm = TRUE)

      if (out_of_range > 0) {
        pct <- round(out_of_range / nrow(df) * 100, 1)
        warnings <- c(warnings, list(
          div(class = "alert alert-info", role = "alert",
              sprintf("ℹ️ %s rows (%.1f%%) have years outside %d-%d range",
                     format(out_of_range, big.mark = ","), pct,
                     YEAR_MIN_DEFAULT, YEAR_MAX_DEFAULT))
        ))
      }
    }

    if (length(warnings) == 0) {
      warnings <- list(
        div(class = "alert alert-success", role = "alert",
            strong("✓ No data quality issues detected"))
      )
    }

    tagList(warnings)
  })

  # Year coverage timeline
  output$check_year_timeline <- plotly::renderPlotly({
    df <- uploaded_df()
    req(!is.null(df), nrow(df) > 0, "Accident Year" %in% names(df))

    years <- suppressWarnings(as.integer(df$`Accident Year`))
    years <- years[!is.na(years) & years >= YEAR_MIN_ABSOLUTE & years <= (YEAR_MAX_DEFAULT + 1)]

    if (length(years) == 0) {
      return(plotly::plotly_empty())
    }

    year_counts <- as.data.frame(table(years))
    names(year_counts) <- c("Year", "Count")
    year_counts$Year <- as.integer(as.character(year_counts$Year))

    plotly::plot_ly(
      year_counts,
      x = ~Year,
      y = ~Count,
      type = "bar",
      marker = list(color = COL_ACTUAL),
      hovertemplate = "Year: %{x}<br>Rows: %{y}<extra></extra>"
    ) %>%
      plotly::layout(
        xaxis = list(title = "Accident Year"),
        yaxis = list(title = "Row Count"),
        margin = list(l = 50, r = 20, t = 20, b = 40)
      ) %>%
      plotly::config(displayModeBar = FALSE)
  })

  # Data completeness score
  output$check_completeness_score <- renderUI({
    df <- uploaded_df()
    req(!is.null(df), nrow(df) > 0)

    scores <- list()

    # Rows with Actual > 0
    if ("Actual" %in% names(df)) {
      actual_vals <- suppressWarnings(as.numeric(df$Actual))
      pct_actual <- round(sum(actual_vals > 0, na.rm = TRUE) / length(actual_vals) * 100, 1)
      scores$actual <- pct_actual
    } else {
      scores$actual <- 0
    }

    # Rows with Expected > 0
    if ("Expected" %in% names(df)) {
      expected_vals <- suppressWarnings(as.numeric(df$Expected))
      pct_expected <- round(sum(expected_vals > 0, na.rm = TRUE) / length(expected_vals) * 100, 1)
      scores$expected <- pct_expected
    } else {
      scores$expected <- 0
    }

    # Overall score (average)
    overall_score <- round(mean(c(scores$actual, scores$expected)), 1)

    # Color based on score
    score_color <- if (overall_score >= 80) "#28a745" else if (overall_score >= 60) "#ffc107" else "#dc3545"

    tagList(
      div(
        style = "text-align: center; padding: 20px;",
        div(
          style = sprintf("font-size: 48px; font-weight: bold; color: %s;", score_color),
          sprintf("%.0f%%", overall_score)
        ),
        div(
          style = "font-size: 18px; color: #666; margin-top: 10px;",
          "Overall Completeness"
        ),
        hr(),
        div(
          style = "text-align: left; padding: 10px;",
          p(sprintf("Actual values populated: %.1f%%", scores$actual)),
          p(sprintf("Expected values populated: %.1f%%", scores$expected))
        )
      )
    )
  })
}
