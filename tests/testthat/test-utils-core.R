# tests/testthat/test-utils-core.R — Tests for core utility functions

test_that("%||% operator returns first non-null value", {
  # Basic NULL handling
  expect_equal(NULL %||% "default", "default")
  expect_equal("value" %||% "default", "value")

  # Empty vector handling
  expect_equal(character(0) %||% "default", "default")
  expect_equal(numeric(0) %||% "default", "default")

  # NA handling for atomic vectors
  expect_equal(NA %||% "default", "default")
  expect_equal(c(NA, NA) %||% "default", "default")

  # Empty string handling

  expect_equal("" %||% "default", "default")
  expect_equal(c("", "") %||% "default", "default")

  # Non-empty values are returned
  expect_equal(0 %||% "default", 0)
  expect_equal(FALSE %||% "default", FALSE)
  expect_equal("text" %||% "default", "text")
  expect_equal(c(1, 2, 3) %||% "default", c(1, 2, 3))
})

test_that("scalar_or returns correct values", {
  # NULL returns default
  expect_equal(scalar_or(NULL, 10), 10)

  # Non-scalar returns default
  expect_equal(scalar_or(c(1, 2), 10), 10)
  expect_equal(scalar_or(1:5, 10), 10)

  # Scalar returns value
  expect_equal(scalar_or(5, 10), 5)
  expect_equal(scalar_or("text", "default"), "text")
  expect_equal(scalar_or(TRUE, FALSE), TRUE)
})

test_that("._dbg only outputs when debug mode enabled", {
  # Disable debug mode
  old_opt <- getOption("ave.debug")
  options(ave.debug = FALSE)

  # Should not produce output
  expect_silent(._dbg("Test message %s", "arg"))

  # Enable debug mode
  options(ave.debug = TRUE)

  # Should produce message
  expect_message(._dbg("Test message %s", "arg"), "Test message arg")

  # Restore original setting
  options(ave.debug = old_opt)
})

test_that("dbg_rows handles various data frame states", {
  old_opt <- getOption("ave.debug")
  options(ave.debug = TRUE)

  # NULL data
  expect_silent(dbg_rows("test", NULL))

  # Empty data frame
  df_empty <- data.frame()
  expect_message(dbg_rows("test", df_empty), "rows=0")

  # Valid data frame
  df <- create_minimal_test_data()
  expect_message(dbg_rows("test", df), "rows=4")

  options(ave.debug = old_opt)
})

test_that("is_raw_sheet_name identifies correct sheet names", {
  expect_true(is_raw_sheet_name("A v E MRG Actuals Expecteds"))
  expect_true(is_raw_sheet_name("AvEMRGActualsExpecteds"))
  expect_false(is_raw_sheet_name("Some Other Sheet"))
  expect_false(is_raw_sheet_name(""))
  expect_false(is_raw_sheet_name(NA))
})
