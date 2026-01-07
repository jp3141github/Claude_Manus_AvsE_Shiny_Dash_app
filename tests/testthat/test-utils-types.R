# tests/testthat/test-utils-types.R — Tests for type conversion utilities

test_that("to_float handles numeric input", {
  expect_equal(to_float(123), 123)
  expect_equal(to_float(123.45), 123.45)
  expect_equal(to_float(c(1, 2, 3)), c(1, 2, 3))
})

test_that("to_float handles string numbers", {
  expect_equal(to_float("123"), 123)
  expect_equal(to_float("123.45"), 123.45)
  expect_equal(to_float(c("1", "2", "3")), c(1, 2, 3))
})

test_that("to_float handles currency formatting", {
  expect_equal(to_float("£1,000"), 1000)
  expect_equal(to_float("£1,234.56"), 1234.56)
  expect_equal(to_float("1,000,000"), 1000000)
})

test_that("to_float handles bracketed negatives", {
  expect_equal(to_float("(100)"), -100)
  expect_equal(to_float("(1,234.56)"), -1234.56)
})
test_that("to_float handles unicode minus characters", {
  # Unicode minus (U+2212)
  expect_equal(to_float("\u2212100"), -100)
  # En dash (U+2013)
  expect_equal(to_float("\u2013100"), -100)
  # Em dash (U+2014)
  expect_equal(to_float("\u2014100"), -100)
})

test_that("to_float handles non-breaking spaces", {
  # Non-breaking space from Excel
  expect_equal(to_float("1\u00A0000"), 1000)
  expect_equal(to_float("1 000 000"), 1000000)
})

test_that("to_float preserves NA", {
  expect_true(is.na(to_float(NA)))
  expect_true(is.na(to_float("NA")))
  expect_equal(to_float(c("1", NA, "3")), c(1, NA, 3))
})

test_that("parse_projection_date_dateonly handles various formats", {
  # DD-MM-YYYY format
  result <- parse_projection_date_dateonly("01-07-2024")
  expect_true(inherits(result, "Date"))
  expect_equal(format(result, "%Y-%m-%d"), "2024-07-01")

  # YYYY-MM-DD format
  result <- parse_projection_date_dateonly("2024-07-01")
  expect_equal(format(result, "%Y-%m-%d"), "2024-07-01")

  # MM/DD/YYYY format
  result <- parse_projection_date_dateonly("07/01/2024")
  expect_true(inherits(result, "Date"))
})

test_that("parse_projection_date_dateonly handles datetime formats", {
  # With time component
  result <- parse_projection_date_dateonly("01-07-2024 10:30:00")
  expect_true(inherits(result, "Date"))
  expect_equal(format(result, "%Y-%m-%d"), "2024-07-01")
})

test_that("parse_projection_date_dateonly handles 8-digit dates", {
  result <- parse_projection_date_dateonly("20240701")
  expect_equal(format(result, "%Y-%m-%d"), "2024-07-01")
})

test_that("parse_projection_date_dateonly handles Excel serial dates", {
  # Excel serial for 2024-07-01 is approximately 45474
  result <- parse_projection_date_dateonly("45474")
  expect_true(inherits(result, "Date"))
})

test_that("parse_projection_date_dateonly handles NA", {
  expect_true(is.na(parse_projection_date_dateonly(NA)))
  expect_true(is.na(parse_projection_date_dateonly("")))
})

test_that("coerce_types handles minimal valid data", {
  df <- create_minimal_test_data()
  result <- coerce_types(df)

  expect_true(is.data.frame(result))
  expect_true("A - E" %in% names(result))
  expect_true(is.numeric(result$Actual))
  expect_true(is.numeric(result$Expected))
})

test_that("coerce_types normalizes Measure column", {
  df <- tibble(
    `Accident Year` = c(2023, 2024),
    Product = c("A", "B"),
    Peril = c("P1", "P2"),
    Measure = c("paid", "INCURRED"),
    Actual = c(100, 200),
    Expected = c(90, 180),
    `Current or Prior` = c("CY", "PY")
  )
  result <- coerce_types(df)

  expect_equal(result$Measure, c("Paid", "Incurred"))
})

test_that("coerce_types handles missing Accident Year variations", {
  df <- tibble(
    accidentyear = c(2023, 2024),
    Product = c("A", "B"),
    Peril = c("P1", "P2"),
    Measure = c("Paid", "Incurred"),
    Actual = c(100, 200),
    Expected = c(90, 180),
    `Current or Prior` = c("CY", "PY")
  )
  result <- coerce_types(df)

  expect_true("Accident Year" %in% names(result))
  expect_equal(result$`Accident Year`, c(2023L, 2024L))
})

test_that("coerce_types normalizes Current or Prior", {
  df <- tibble(
    `Accident Year` = c(2023, 2024, 2023, 2024),
    Product = rep("A", 4),
    Peril = rep("P1", 4),
    Measure = rep("Paid", 4),
    Actual = rep(100, 4),
    Expected = rep(90, 4),
    `Current or Prior` = c("PRIOR", "CURRENT", "Prior", "Current")
  )
  result <- coerce_types(df)

  expect_equal(result$`Current or Prior`, c("PY", "CY", "PY", "CY"))
})

test_that("coerce_types handles edge case data", {
  df <- create_edge_case_data()

  # Should not error
  expect_no_error(result <- coerce_types(df))
  expect_true(is.data.frame(result))
})

test_that("coerce_types creates A - E column", {
  df <- tibble(
    `Accident Year` = 2023,
    Product = "A",
    Peril = "P1",
    Measure = "Paid",
    Actual = 1000,
    Expected = 900,
    `Current or Prior` = "CY"
  )
  result <- coerce_types(df)

  expect_true("A - E" %in% names(result))
  expect_equal(result$`A - E`, 100)
})

test_that("coerce_types clamps invalid years", {
  df <- tibble(
    `Accident Year` = c(1900, 2023, 3000),  # Invalid years
    Product = rep("A", 3),
    Peril = rep("P1", 3),
    Measure = rep("Paid", 3),
    Actual = rep(100, 3),
    Expected = rep(90, 3),
    `Current or Prior` = rep("CY", 3)
  )
  result <- coerce_types(df)

  expect_true(is.na(result$`Accident Year`[1]))  # 1900 is invalid
  expect_equal(result$`Accident Year`[2], 2023L)  # Valid
  expect_true(is.na(result$`Accident Year`[3]))  # 3000 is invalid
})

test_that("coerce_types handles unicode in numeric columns", {
  df <- create_unicode_test_data()

  result <- coerce_types(df)
  expect_true(is.numeric(result$Actual))
  expect_true(is.numeric(result$Expected))
})
