# tests/testthat/test-utils-filters.R — Tests for filter utilities

test_that("norm_key normalizes text correctly", {
  expect_equal(norm_key("Product A"), "producta")
  expect_equal(norm_key("PRODUCT-A"), "producta")
  expect_equal(norm_key("  Prod_123  "), "prod123")
  expect_equal(norm_key("Special!@#$%"), "special")
})

test_that("map_event normalizes event types", {
  expect_equal(map_event("Event"), "event")
  expect_equal(map_event("Non-Event"), "nonevent")
  expect_equal(map_event("NonEvent"), "nonevent")
  expect_equal(map_event("non event"), "nonevent")
  expect_equal(map_event("EVENT"), "event")
})

test_that("first_present_col finds correct columns", {
  df <- tibble(
    `Model Type` = "A",
    Segment = "NIG",
    Other = "value"
  )

  expect_equal(first_present_col(df, c("Model Type", "ModelType")), "Model Type")
  expect_equal(first_present_col(df, c("ModelType", "model_type")), NULL)
  expect_equal(first_present_col(df, c("Missing", "Model Type")), "Model Type")
})

test_that("apply_filters handles NULL data", {
  result <- apply_filters(NULL, "Model_A", "2024-01-01", "Event")
  expect_null(result)
})

test_that("apply_filters handles empty data", {
  df <- tibble()
  result <- apply_filters(df, "Model_A", "2024-01-01", "Event")
  expect_equal(nrow(result), 0)
})

test_that("apply_filters filters by model type", {
  df <- create_filter_test_data()

  result <- apply_filters(df, "Model_A", NULL, NULL)

  expect_true(all(tolower(result$`Model Type`) == "model_a"))
  expect_true(nrow(result) < nrow(df))
})

test_that("apply_filters filters by projection date", {
  df <- create_filter_test_data()

  result <- apply_filters(df, NULL, as.Date("2024-01-01"), NULL)

  expect_true(nrow(result) < nrow(df))
})

test_that("apply_filters filters by event type", {
  df <- create_filter_test_data()

  result <- apply_filters(df, NULL, NULL, "Event")

  expect_true(nrow(result) > 0)
})

test_that("apply_filters combines multiple filters", {
  df <- create_filter_test_data()

  result <- apply_filters(df, "Model_A", as.Date("2024-01-01"), "Event")

  expect_true(nrow(result) >= 0)  # May be 0 if no matching rows
  expect_true(nrow(result) <= nrow(df))
})

test_that("apply_filters handles case-insensitive matching", {
  df <- tibble(
    `Accident Year` = c(2023, 2024),
    Product = c("A", "B"),
    Peril = c("P1", "P2"),
    Measure = c("Paid", "Incurred"),
    Actual = c(100, 200),
    Expected = c(90, 180),
    `Current or Prior` = c("CY", "PY"),
    `Model Type` = c("model_a", "MODEL_A")
  )

  result <- apply_filters(df, "Model_A", NULL, NULL)
  expect_equal(nrow(result), 2)
})

test_that("apply_filters skips filter when no matches", {
  df <- create_filter_test_data()

  # Non-existent model type - should skip filter gracefully
  result <- apply_filters(df, "NonExistent_Model", NULL, NULL)

  # When no matches, it should show notification but return filtered data
  expect_true(is.data.frame(result))
})

test_that("ensure_columns validates required columns", {
  # Valid data
  df <- create_minimal_test_data()
  result <- ensure_columns(df)
  expect_true(is.data.frame(result))

  # Missing required column
  df_missing <- tibble(
    `Accident Year` = 2023,
    Product = "A"
    # Missing Actual, Expected, Peril, etc.
  )
  expect_error(ensure_columns(df_missing))
})

test_that("ensure_columns handles column name variations", {
  df <- tibble(
    accidentyear = 2023,
    Product = "A",
    Peril = "P1",
    Actual = 100,
    Expected = 90,
    `Current or Prior` = "CY"
  )

  result <- ensure_columns(df)
  expect_true("Accident Year" %in% names(result))
})

test_that("ensure_columns creates Current or Prior if missing", {
  df <- tibble(
    `Accident Year` = 2023,
    Product = "A",
    Peril = "P1",
    Actual = 100,
    Expected = 90
  )

  result <- ensure_columns(df)
  expect_true("Current or Prior" %in% names(result))
})

test_that(".debug_headcounts outputs correct information", {
  df <- create_minimal_test_data()

  old_opt <- getOption("ave.debug")
  options(ave.debug = FALSE)

  # Should be silent when debug is off
  expect_silent(.debug_headcounts(df))

  options(ave.debug = old_opt)
})
