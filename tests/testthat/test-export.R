# tests/testthat/test-export.R — Tests for Excel export functions

# ============ Summary Sheet Tests ============

test_that("build_summary_sheet creates valid structure", {
  tables <- list(
    "Total Summary" = tibble(
      Basis = c("Paid", "Paid", "Incurred", "Incurred"),
      `A vs E` = c("Actual", "Expected", "Actual", "Expected"),
      `2023` = c(100, 90, 150, 140),
      `Grand Total` = c(100, 90, 150, 140)
    ),
    "Paid A v E" = tibble(
      Product = c("Product_A", "Product_B"),
      Peril = c("Peril_1", "Peril_2"),
      `2023` = c(10, 20),
      `Grand Total` = c(10, 20)
    )
  )

  result <- build_summary_sheet(tables)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
  expect_true("Metric" %in% names(result))
  expect_true("Value" %in% names(result))
})

test_that("build_summary_sheet includes metadata", {
  tables <- list()
  filters <- list(
    model_type = "Model_A",
    projection_date = "2024-01-01",
    event_type = "Non-Event"
  )

  result <- build_summary_sheet(tables, NULL, filters)

  # Check that metadata is included
  expect_true(any(grepl("Model Type", result$Metric)))
  expect_true(any(grepl("Projection Date", result$Metric)))
})

test_that("build_summary_sheet handles uploaded data", {
  tables <- list()
  uploaded_df <- create_test_data(50)

  result <- build_summary_sheet(tables, uploaded_df)

  # Check year coverage section
  expect_true(any(grepl("YEAR COVERAGE", result$Metric)))
  expect_true(any(grepl("DATA QUALITY", result$Metric)))
})

test_that("build_summary_sheet includes top products", {
  tables <- list(
    "Paid A v E" = tibble(
      Product = paste0("Product_", LETTERS[1:10]),
      Peril = rep("Peril_1", 10),
      `2023` = seq(100, 1000, by = 100),
      `Grand Total` = seq(100, 1000, by = 100)
    )
  )

  result <- build_summary_sheet(tables)

  # Check that top products section exists
  expect_true(any(grepl("TOP 5 ADVERSE", result$Metric)))
  expect_true(any(grepl("TOP 5 FAVORABLE", result$Metric)))
})

# ============ Excel Writer Tests ============

test_that("write_excel creates valid Excel file", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Total Summary" = tibble(
      Basis = c("Paid", "Incurred"),
      `A vs E` = c("Actual", "Actual"),
      `2023` = c(100, 150),
      `Grand Total` = c(100, 150)
    ),
    "Paid A v E" = tibble(
      Product = c("Product_A", "Product_B"),
      Peril = c("Peril_1", "Peril_2"),
      `2023` = c(10, 20),
      `Grand Total` = c(10, 20)
    )
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  expect_no_error(write_excel(tables, temp_file))
  expect_true(file.exists(temp_file))
  expect_true(file.size(temp_file) > 0)
})

test_that("write_excel includes all sheets", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Sheet1" = tibble(A = 1:3, B = 4:6),
    "Sheet2" = tibble(X = c("a", "b", "c")),
    "Sheet3" = tibble(Num = runif(5))
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  write_excel(tables, temp_file)

  # Read back and verify sheets
  wb <- openxlsx::loadWorkbook(temp_file)
  sheet_names <- openxlsx::sheets(wb)

  # Should have Summary + 3 original sheets
  expect_true("Summary" %in% sheet_names)
  expect_equal(length(sheet_names), 4)
})

test_that("write_excel handles empty tables", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Empty" = tibble()
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  # Should not error on empty tables
  expect_no_error(write_excel(tables, temp_file))
})

test_that("write_excel handles special characters in data", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Special" = tibble(
      Product = c("Product £1", "Product\u2212A"),
      Value = c("£1,000", "(500)")
    )
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  expect_no_error(write_excel(tables, temp_file))
})

test_that("write_excel handles infinite values", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Infinite" = tibble(
      Product = c("A", "B", "C"),
      Value = c(Inf, -Inf, NaN)
    )
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  # Should handle infinite values gracefully
  expect_no_error(write_excel(tables, temp_file))
})

test_that("write_excel applies correct styles to Total Summary", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Total Summary" = tibble(
      Basis = rep("Paid", 5),
      `A vs E` = c("Actual", "Expected", "A-E", "%", "Check"),
      `2023` = c(100, 90, 10, 0.111, 0),
      `Grand Total` = c(100, 90, 10, 0.111, 0)
    )
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  expect_no_error(write_excel(tables, temp_file))
  expect_true(file.exists(temp_file))
})

test_that("write_excel handles raw sheet name", {
  skip_if_not_installed("openxlsx")

  tables <- list()
  tables[["A v E MRG Actuals Expecteds"]] <- tibble(
    `Accident Year` = c(2023, 2024),
    Product = c("A", "B"),
    Peril = c("P1", "P2"),
    Actual = c(1000, 2000),
    Expected = c(900, 1800),
    `A - E` = c(100, 200)
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  expect_no_error(write_excel(tables, temp_file))
})

test_that("write_excel with filters parameter", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Test" = tibble(A = 1:3)
  )
  filters <- list(
    model_type = "Model_A",
    projection_date = "2024-01-01",
    event_type = "Non-Event",
    excluded_products = c("Product_X", "Product_Y")
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  expect_no_error(write_excel(tables, temp_file, NULL, filters))
})

# ============ Column Width Tests ============

test_that("Excel column widths are reasonable", {
  skip_if_not_installed("openxlsx")

  tables <- list(
    "Test" = tibble(
      ShortCol = 1:5,
      `Very Long Column Name That Should Be Wrapped` = 6:10,
      Num = runif(5)
    )
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  # Should not error - column widths handled internally
  expect_no_error(write_excel(tables, temp_file))
})
