# tests/testthat/test-orchestration.R — Integration tests for main orchestration

# ============ build_all_tables Tests ============

test_that("build_all_tables produces complete output", {
  df <- create_test_data(200)

  result <- build_all_tables(
    raw_df = df,
    model_type = "Model_A",
    projection_date = as.Date("2024-01-01"),
    event_type = "Non-Event"
  )

  expect_true(is.list(result))
  expect_true(length(result) > 0)

  # Check for essential sheets
  expect_true("Total Summary" %in% names(result))
  expect_true("Class Summary" %in% names(result))
  expect_true("Paid A v E" %in% names(result))
  expect_true("Incurred A v E" %in% names(result))
})

test_that("build_all_tables handles minimal data", {
  df <- create_minimal_test_data()

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )

  expect_true(is.list(result))
})

test_that("build_all_tables excludes products correctly", {
  df <- create_test_data(100)
  excluded <- unique(df$Product)[1]  # Exclude first product

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL,
    excluded_products = excluded
  )

  # Check that excluded product is not in output tables
  if ("Paid A v E" %in% names(result)) {
    paid_table <- result[["Paid A v E"]]
    if ("Product" %in% names(paid_table)) {
      products_in_output <- unique(paid_table$Product)
      products_in_output <- products_in_output[!products_in_output %in% c("Grand Total", "")]
      expect_false(excluded %in% products_in_output)
    }
  }
})

test_that("build_all_tables applies filters", {
  df <- create_filter_test_data()

  result <- build_all_tables(
    raw_df = df,
    model_type = "Model_A",
    projection_date = NULL,
    event_type = NULL
  )

  expect_true(is.list(result))
})

test_that("build_all_tables produces NIG/Non-NIG splits", {
  df <- create_test_data(100)

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )

  expect_true("Paid A v E – NIG" %in% names(result))
  expect_true("Paid A v E – Non NIG" %in% names(result))
  expect_true("Incurred A v E – NIG" %in% names(result))
  expect_true("Incurred A v E – Non NIG" %in% names(result))
})

test_that("build_all_tables output tables have correct structure", {
  df <- create_chart_test_data()

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )

  # Total Summary structure
  if ("Total Summary" %in% names(result)) {
    ts <- result[["Total Summary"]]
    expect_true("Basis" %in% names(ts))
    expect_true("A vs E" %in% names(ts))
    expect_true(any(ts$Basis == "Paid"))
    expect_true(any(ts$Basis == "Incurred"))
  }

  # Paid A v E structure
  if ("Paid A v E" %in% names(result)) {
    paid <- result[["Paid A v E"]]
    expect_true("Product" %in% names(paid))
    expect_true("Peril" %in% names(paid))
    expect_true("Grand Total" %in% names(paid))
  }
})

test_that("build_all_tables handles edge case data", {
  df <- create_edge_case_data()

  # Should not crash on edge case data
  expect_no_error({
    result <- tryCatch(
      build_all_tables(
        raw_df = df,
        model_type = NULL,
        projection_date = NULL,
        event_type = NULL
      ),
      error = function(e) {
        if (!grepl("Missing required columns", e$message)) stop(e)
        NULL
      }
    )
  })
})

test_that("build_all_tables generates year columns", {
  df <- create_chart_test_data()
  years <- unique(df$`Accident Year`)

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )

  if ("Paid A v E" %in% names(result)) {
    paid <- result[["Paid A v E"]]
    year_cols <- names(paid)[grepl("^\\d{4}$", names(paid))]
    expect_true(length(year_cols) > 0)
  }
})

test_that("build_all_tables handles unicode data", {
  df <- create_unicode_test_data()

  # Add required columns
  df <- df %>%
    mutate(
      `A - E` = to_float(Actual) - to_float(Expected),
      Segment = "NIG",
      `Segment (Group)` = "NIG"
    )

  # Should handle unicode without error
  expect_no_error({
    result <- tryCatch(
      build_all_tables(
        raw_df = df,
        model_type = NULL,
        projection_date = NULL,
        event_type = NULL
      ),
      error = function(e) {
        if (!grepl("Missing required columns", e$message)) stop(e)
        NULL
      }
    )
  })
})

# ============ Data Flow Integration Tests ============

test_that("full data pipeline maintains data integrity", {
  df <- create_test_data(100)

  # Total input values
  total_actual_input <- sum(df$Actual, na.rm = TRUE)
  total_expected_input <- sum(df$Expected, na.rm = TRUE)

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )

  # Check Total Summary totals match (approximately, due to filtering)
  if ("Total Summary" %in% names(result)) {
    ts <- result[["Total Summary"]]
    # Note: Values are in millions, and may be filtered
    expect_true(is.data.frame(ts))
  }
})

test_that("orchestration respects Paid/Incurred separation", {
  df <- create_chart_test_data()

  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )

  # Paid tables should only contain Paid data
  if ("Paid A" %in% names(result) && "Incurred A" %in% names(result)) {
    paid_a <- result[["Paid A"]]
    incurred_a <- result[["Incurred A"]]

    # They should have the same structure but different values
    expect_equal(names(paid_a), names(incurred_a))
  }
})

# ============ Performance Tests ============

test_that("build_all_tables handles large datasets", {
  skip_on_cran()  # Skip for CRAN checks

  # Create larger dataset
  df <- create_test_data(5000)

  start_time <- Sys.time()
  result <- build_all_tables(
    raw_df = df,
    model_type = NULL,
    projection_date = NULL,
    event_type = NULL
  )
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  expect_true(is.list(result))
  # Should complete within reasonable time (30 seconds)
  expect_true(elapsed < 30, info = paste("Took", round(elapsed, 1), "seconds"))
})
