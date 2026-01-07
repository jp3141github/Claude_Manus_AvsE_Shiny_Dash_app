# tests/testthat/test-builders.R — Tests for data builder functions

# ============ Core Builder Tests ============

test_that("py_cy_split splits data correctly", {
  df <- create_minimal_test_data()

  result <- py_cy_split(df, "A - E")

  expect_true(is.list(result))
  expect_true("g_peril" %in% names(result))
  expect_true("g_prod" %in% names(result))
  expect_true(is.data.frame(result$g_peril))
  expect_true(is.data.frame(result$g_prod))
  expect_true("PY" %in% names(result$g_peril) || "CY" %in% names(result$g_peril))
})

test_that("three_block_ave_table combines data correctly", {
  df <- create_minimal_test_data()
  split_data <- py_cy_split(df, "A - E")

  result <- three_block_ave_table(split_data$g_peril, split_data$g_prod)

  expect_true(is.data.frame(result))
  expect_true("Product" %in% names(result))
  expect_true("Peril" %in% names(result))
})

test_that("append_grand_total_row_pvt adds grand total", {
  df <- tibble(
    Product = c("A", "A", "B", "B"),
    Peril = c("P1", "TOTAL", "P1", "TOTAL"),
    `2023` = c(100, 100, 200, 200),
    `2024` = c(150, 150, 250, 250),
    `Grand Total` = c(250, 250, 450, 450)
  )

  result <- append_grand_total_row_pvt(df)

  expect_true(nrow(result) == nrow(df) + 1)
  expect_true("Grand Total" %in% result$Product)
})

test_that("append_grand_total_row_pvt handles NULL/empty data", {
  expect_null(append_grand_total_row_pvt(NULL))
  expect_equal(nrow(append_grand_total_row_pvt(tibble())), 0)
})

test_that("ensure_id_cols adds missing columns", {
  df <- tibble(Product = "A")

  result <- ensure_id_cols(df)

  expect_true("Peril" %in% names(result))
  expect_true("Class/Peril" %in% names(result))
})

test_that(".force_text_ids_all converts to character", {
  df <- tibble(
    Product = factor(c("A", "B")),
    Peril = factor(c("P1", "P2")),
    Value = c(100, 200)
  )

  result <- .force_text_ids_all(df)

  expect_true(is.character(result$Product))
  expect_true(is.character(result$Peril))
})

test_that("safe_levels_class creates ordered unique levels", {
  x <- c("Product_C", "Product_A", "Grand Total", "Product_B", "", NA, "0")

  result <- safe_levels_class(x)

  expect_true(is.character(result))
  expect_false("" %in% result)
  expect_false(any(is.na(result)))
})

# ============ Pivot Builder Tests ============

test_that("pivot_product_peril_by_year creates correct structure", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- pivot_product_peril_by_year(df, "Actual", years)

  expect_true(is.data.frame(result))
  expect_true("Product" %in% names(result))
  expect_true("Peril" %in% names(result))
  expect_true("Grand Total" %in% names(result))

  # Check year columns exist
  for (yr in years) {
    expect_true(as.character(yr) %in% names(result), info = paste("Year", yr, "missing"))
  }
})

test_that("pivot_product_peril_by_year handles empty years", {
  df <- create_minimal_test_data()

  result <- pivot_product_peril_by_year(df, "Actual", integer(0))

  expect_true(is.data.frame(result))
  expect_true("Grand Total" %in% names(result))
})

test_that("build_paid_ave produces valid output", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_paid_ave(df, years)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
  expect_true("Grand Total" %in% names(result))
  # Should have Grand Total row
  expect_true(any(result$Product == "Grand Total"))
})

test_that("build_incurred_ave produces valid output", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_incurred_ave(df, years)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
})

test_that("build_paid_a produces valid output", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_paid_a(df, years)

  expect_true(is.data.frame(result))
  expect_true(all(result$`Grand Total` >= 0, na.rm = TRUE))  # Actuals should be positive
})

test_that("build_paid_e produces valid output", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_paid_e(df, years)

  expect_true(is.data.frame(result))
  expect_true(all(result$`Grand Total` >= 0, na.rm = TRUE))  # Expected should be positive
})

test_that("build_incurred_a produces valid output", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_incurred_a(df, years)

  expect_true(is.data.frame(result))
})

test_that("build_incurred_e produces valid output", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_incurred_e(df, years)

  expect_true(is.data.frame(result))
})

# ============ Total Summary Builder Tests ============

test_that("build_total_summary creates correct structure", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_total_summary(df, years)

  expect_true(is.data.frame(result))
  expect_true("Basis" %in% names(result))
  expect_true("A vs E" %in% names(result))
  expect_true("Grand Total" %in% names(result))

  # Check for both Paid and Incurred blocks
  expect_true("Paid" %in% result$Basis)
  expect_true("Incurred" %in% result$Basis)

  # Check for all A vs E row types
  expect_true("Actual" %in% result$`A vs E`)
  expect_true("Expected" %in% result$`A vs E`)
  expect_true("A-E" %in% result$`A vs E`)
  expect_true("%" %in% result$`A vs E`)
})

test_that("build_total_summary handles edge cases", {
  df <- create_minimal_test_data()
  years <- unique(df$`Accident Year`)

  result <- build_total_summary(df, years)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
})

test_that("build_total_summary year columns are numeric", {
  df <- create_chart_test_data()
  years <- 2020:2024

  result <- build_total_summary(df, years)

  for (yr in as.character(years)) {
    expect_true(is.numeric(result[[yr]]), info = paste("Year", yr, "not numeric"))
  }
})

# ============ Class Summary Builder Tests ============

test_that("class_summary_core creates merged table", {
  df <- create_chart_test_data()

  result <- class_summary_core(df)

  expect_true(is.data.frame(result))
  expect_true("Product" %in% names(result))
  expect_true("Peril" %in% names(result))

  # Check for required columns
  required_cols <- c("PY_Paid", "CY_Paid", "PY_Incurred", "CY_Incurred",
                     "Total_Paid", "Total_Incurred")
  for (col in required_cols) {
    expect_true(col %in% names(result), info = paste("Missing column:", col))
  }
})

test_that("class_summary_core handles empty Paid or Incurred", {
  # Only Paid data
  df <- create_minimal_test_data() %>%
    filter(Measure == "Paid")

  result <- class_summary_core(df)

  expect_true(is.data.frame(result))
})
