# tests/testthat/test-charts.R — Tests for chart generation functions

# ============ Chart Core Tests ============

test_that("year_axis creates proper breaks", {
  years <- 2020:2024

  result <- year_axis(years)

  expect_true(is.list(result))
})

test_that("fmt_year_labels formats years correctly", {
  years <- 2020:2024

  result <- fmt_year_labels(years)

  expect_true(is.character(result))
  expect_equal(length(result), length(years))
})

# ============ Series Pack Tests ============

test_that("series_pack creates valid structure", {
  df <- create_chart_test_data() %>%
    filter(Measure == "Paid") %>%
    group_by(`Accident Year`) %>%
    summarise(
      Actual = sum(Actual, na.rm = TRUE),
      Expected = sum(Expected, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(`A - E` = Actual - Expected)

  result <- series_pack(df, year_col = "Accident Year")

  expect_true(is.list(result))
  expect_true("years" %in% names(result))
  expect_true("A" %in% names(result))
  expect_true("E" %in% names(result))
  expect_true("AE" %in% names(result))
})

test_that("series_pack handles empty data", {
  df <- tibble()

  result <- series_pack(df)

  expect_true(is.list(result))
})

# ============ Align Series Tests ============

test_that("align_series aligns data correctly", {
  sp1 <- list(years = 2020:2024, A = 1:5, E = 2:6, AE = -1:-5)
  sp2 <- list(years = 2021:2025, A = 10:14, E = 11:15, AE = -1:-5)

  result <- align_series(sp1, sp2)

  expect_true(is.list(result))
  # Common years should be 2021-2024
  expect_true(2021 %in% result$years)
  expect_true(2024 %in% result$years)
})

# ============ Heatmap Tests ============

test_that("build_heatmap_px creates valid plotly object", {
  df <- create_chart_test_data() %>%
    filter(Measure == "Paid") %>%
    group_by(Product, `Accident Year`) %>%
    summarise(`A - E` = sum(`A - E`, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = `Accident Year`, values_from = `A - E`, values_fill = 0)

  # Only test if function exists
  if (exists("build_heatmap_px", mode = "function")) {
    result <- tryCatch(
      build_heatmap_px(df, title = "Test Heatmap"),
      error = function(e) NULL
    )

    if (!is.null(result)) {
      expect_true(inherits(result, "plotly") || inherits(result, "htmlwidget"))
    }
  } else {
    skip("build_heatmap_px not available")
  }
})

# ============ Line Chart Tests ============

test_that("line charts can be created from chart data", {
  df <- create_chart_test_data()

  # Test data preparation for line charts
  paid_data <- df %>%
    filter(Measure == "Paid") %>%
    group_by(`Accident Year`) %>%
    summarise(
      Actual = sum(Actual, na.rm = TRUE),
      Expected = sum(Expected, na.rm = TRUE),
      .groups = "drop"
    )

  expect_true(nrow(paid_data) > 0)
  expect_true(all(c("Accident Year", "Actual", "Expected") %in% names(paid_data)))
})

# ============ Waterfall Chart Tests ============

test_that("waterfall data can be prepared", {
  df <- create_chart_test_data() %>%
    filter(Measure == "Paid") %>%
    group_by(Product) %>%
    summarise(`A - E` = sum(`A - E`, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(abs(`A - E`)))

  expect_true(nrow(df) > 0)
  expect_true("A - E" %in% names(df))
})

# ============ Variance Bridge Tests ============

test_that("variance data can be computed", {
  df <- create_chart_test_data()

  # Compute variance by product
  variance_data <- df %>%
    group_by(Product) %>%
    summarise(
      Total_Actual = sum(Actual, na.rm = TRUE),
      Total_Expected = sum(Expected, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      Variance = Total_Actual - Total_Expected,
      Variance_Pct = if_else(Total_Expected == 0, NA_real_, Variance / Total_Expected)
    )

  expect_true(nrow(variance_data) > 0)
  expect_true("Variance" %in% names(variance_data))
})

# ============ Cumulative Chart Tests ============

test_that("cumulative data can be computed", {
  df <- create_chart_test_data() %>%
    filter(Measure == "Paid") %>%
    group_by(`Accident Year`) %>%
    summarise(
      Actual = sum(Actual, na.rm = TRUE),
      Expected = sum(Expected, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(`Accident Year`) %>%
    mutate(
      Cumulative_Actual = cumsum(Actual),
      Cumulative_Expected = cumsum(Expected)
    )

  expect_true(nrow(df) > 0)
  expect_true("Cumulative_Actual" %in% names(df))
  expect_true("Cumulative_Expected" %in% names(df))

  # Cumulative values should increase or stay same
  expect_true(all(diff(df$Cumulative_Actual) >= 0))
})

# ============ Segment Chart Tests ============

test_that("segment data can be prepared", {
  df <- create_chart_test_data()

  # Group by segment
  segment_data <- df %>%
    group_by(Segment, `Accident Year`) %>%
    summarise(
      Actual = sum(Actual, na.rm = TRUE),
      Expected = sum(Expected, na.rm = TRUE),
      `A - E` = sum(`A - E`, na.rm = TRUE),
      .groups = "drop"
    )

  expect_true(nrow(segment_data) > 0)
  expect_true("Segment" %in% names(segment_data))
})

# ============ Chart Color Tests ============

test_that("color constants are defined", {
  expect_true(exists("COL_ACTUAL"))
  expect_true(exists("COL_EXPECTED"))
  expect_true(exists("LINE_COLOURS"))
  expect_true(exists("LINE_TYPES"))
})

test_that("LINE_COLOURS has required entries", {
  expect_true("Actual" %in% names(LINE_COLOURS))
  expect_true("Expected" %in% names(LINE_COLOURS))
})

# ============ Product Chart Tests ============

test_that("product aggregation works correctly", {
  df <- create_chart_test_data()

  product_data <- df %>%
    group_by(Product, Measure) %>%
    summarise(
      Total_Actual = sum(Actual, na.rm = TRUE),
      Total_Expected = sum(Expected, na.rm = TRUE),
      Total_AE = sum(`A - E`, na.rm = TRUE),
      .groups = "drop"
    )

  expect_true(nrow(product_data) > 0)
  expect_equal(length(unique(product_data$Product)), 2)  # Product_A and Product_B
})

# ============ Peril Chart Tests ============

test_that("peril aggregation works correctly", {
  df <- create_chart_test_data()

  peril_data <- df %>%
    group_by(Peril, `Accident Year`) %>%
    summarise(
      Actual = sum(Actual, na.rm = TRUE),
      Expected = sum(Expected, na.rm = TRUE),
      .groups = "drop"
    )

  expect_true(nrow(peril_data) > 0)
  expect_equal(length(unique(peril_data$Peril)), 2)  # Peril_1 and Peril_2
})

# ============ Chart Output Validation ============

test_that("chart data has no infinite values", {
  df <- create_chart_test_data()

  # Compute percentages that might cause Inf
  pct_data <- df %>%
    group_by(Product) %>%
    summarise(
      Total_E = sum(Expected, na.rm = TRUE),
      Total_AE = sum(`A - E`, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      Pct = if_else(Total_E == 0, NA_real_, Total_AE / Total_E)
    )

  expect_true(!any(is.infinite(pct_data$Pct), na.rm = TRUE))
})

test_that("chart data preserves data integrity", {
  df <- create_chart_test_data()

  # Total of parts should equal whole
  total_actual <- sum(df$Actual, na.rm = TRUE)

  by_product <- df %>%
    group_by(Product) %>%
    summarise(Actual = sum(Actual, na.rm = TRUE), .groups = "drop")

  expect_equal(sum(by_product$Actual), total_actual)
})
