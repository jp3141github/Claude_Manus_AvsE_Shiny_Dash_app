# tests/testthat/test-constants.R — Tests for constants and configuration

# ============ SHEET_NAMES Tests ============

test_that("SHEET_NAMES contains required sheets", {
  expect_true(exists("SHEET_NAMES"))
  expect_true(is.list(SHEET_NAMES))

  required_sheets <- c(
    "total_summary", "class_summary", "class_peril_summary",
    "paid_ave", "incurred_ave", "paid_a", "paid_e",
    "incurred_a", "incurred_e", "raw"
  )

  for (sheet in required_sheets) {
    expect_true(sheet %in% names(SHEET_NAMES), info = paste("Missing:", sheet))
  }
})

test_that("SHEET_RENAME_MAP provides correct mappings", {
  expect_true(exists("SHEET_RENAME_MAP"))

  # Check known mappings
  expect_true("Paid AvE" %in% names(SHEET_RENAME_MAP))
  expect_equal(SHEET_RENAME_MAP[["Paid AvE"]], "Paid A v E")
})

# ============ Year Constants Tests ============

test_that("YEAR_MIN_DEFAULT is reasonable", {
  expect_true(exists("YEAR_MIN_DEFAULT"))
  expect_true(YEAR_MIN_DEFAULT >= 1980)
  expect_true(YEAR_MIN_DEFAULT <= 2020)
})

test_that("YEAR_MAX_DEFAULT is current year", {
  expect_true(exists("YEAR_MAX_DEFAULT"))
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  expect_true(YEAR_MAX_DEFAULT >= current_year - 1)
  expect_true(YEAR_MAX_DEFAULT <= current_year + 1)
})

test_that("YEAR_FORCE_INCLUDE contains recent years", {
  expect_true(exists("YEAR_FORCE_INCLUDE"))
  expect_true(is.integer(YEAR_FORCE_INCLUDE) || is.numeric(YEAR_FORCE_INCLUDE))
  expect_true(length(YEAR_FORCE_INCLUDE) >= 1)
})

# ============ Color Constants Tests ============

test_that("Color constants are valid hex codes", {
  color_vars <- c("COL_ACTUAL", "COL_EXPECTED", "COL_HEAT_POS",
                  "COL_HEAT_NEG", "COL_GOOD_AE", "COL_BAD_AE")

  hex_pattern <- "^#[0-9A-Fa-f]{6}$"

  for (var in color_vars) {
    if (exists(var)) {
      color <- get(var)
      expect_true(grepl(hex_pattern, color), info = paste(var, "=", color))
    }
  }
})

test_that("LINE_COLOURS has Actual and Expected", {
  expect_true(exists("LINE_COLOURS"))
  expect_true("Actual" %in% names(LINE_COLOURS))
  expect_true("Expected" %in% names(LINE_COLOURS))
})

test_that("LINE_TYPES has valid values", {
  expect_true(exists("LINE_TYPES"))
  expect_true("Actual" %in% names(LINE_TYPES))
  expect_true("Expected" %in% names(LINE_TYPES))

  # Valid line types
  valid_types <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")
  expect_true(LINE_TYPES[["Actual"]] %in% valid_types)
  expect_true(LINE_TYPES[["Expected"]] %in% valid_types)
})

# ============ Performance Constants Tests ============

test_that("RAW_MAX_ROWS_IN_RESULTS is reasonable", {
  if (exists("RAW_MAX_ROWS_IN_RESULTS")) {
    expect_true(RAW_MAX_ROWS_IN_RESULTS >= 10000)
    expect_true(RAW_MAX_ROWS_IN_RESULTS <= 1000000)
  }
})

test_that("RAW_FAST_SCROLLER_ROWS is less than max", {
  if (exists("RAW_FAST_SCROLLER_ROWS") && exists("RAW_MAX_ROWS_IN_RESULTS")) {
    expect_true(RAW_FAST_SCROLLER_ROWS <= RAW_MAX_ROWS_IN_RESULTS)
  }
})

# ============ Feature Flags Tests ============

test_that("Feature flags are boolean", {
  flag_vars <- c("IN_BROWSER", "GENERATE_STATIC_PNGS", "ENABLE_ASSISTANT")

  for (var in flag_vars) {
    if (exists(var)) {
      flag <- get(var)
      expect_true(is.logical(flag), info = paste(var, "is not logical"))
    }
  }
})
