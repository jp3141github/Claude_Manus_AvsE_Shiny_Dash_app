# tests/testthat/test-utils-sort-join.R — Tests for sorting and join utilities

# ============ Sort Levels Tests ============

test_that("sorted_levels_az sorts alphabetically", {
  input <- c("Zebra", "Apple", "Mango", "Banana")

  result <- sorted_levels_az(input)

  expect_equal(result, c("Apple", "Banana", "Mango", "Zebra"))
})

test_that("sorted_levels_az removes empty and zero values", {
  input <- c("Apple", "", "0", "0.0", NA, "Banana")

  result <- sorted_levels_az(input)

  expect_equal(result, c("Apple", "Banana"))
  expect_false("" %in% result)
  expect_false("0" %in% result)
  expect_false(any(is.na(result)))
})

test_that("sorted_levels_az trims whitespace", {
  input <- c("  Apple  ", "Banana", "  Cherry")

  result <- sorted_levels_az(input)

  expect_equal(result, c("Apple", "Banana", "Cherry"))
})

test_that("sorted_levels_az returns unique values", {
  input <- c("Apple", "Apple", "Banana", "Banana", "Cherry")

  result <- sorted_levels_az(input)

  expect_equal(result, c("Apple", "Banana", "Cherry"))
})

# ============ Peril Levels Tests ============

test_that("levels_peril_total_last puts TOTAL at end", {
  input <- c("Peril_A", "TOTAL", "Peril_B", "Peril_C")

  result <- levels_peril_total_last(input)

  expect_equal(result[length(result)], "TOTAL")
  expect_equal(result[1:3], c("Peril_A", "Peril_B", "Peril_C"))
})

test_that("levels_peril_total_last handles case variations", {
  input <- c("Peril_A", "total", "Total", "TOTAL")

  result <- levels_peril_total_last(input)

  expect_true(any(grepl("TOTAL", result, ignore.case = TRUE)))
  expect_equal(result[1], "Peril_A")
})

test_that("levels_peril_total_last handles no TOTAL", {
  input <- c("Peril_A", "Peril_B", "Peril_C")

  result <- levels_peril_total_last(input)

  expect_false("TOTAL" %in% result)
  expect_equal(length(result), 3)
})

# ============ Product Levels Tests ============

test_that("levels_product_gt_last puts Grand Total last", {
  input <- c("Product_A", "Grand Total", "Product_B")

  result <- levels_product_gt_last(input)

  expect_equal(result[length(result)], "Grand Total")
})

test_that("levels_product_gt_last puts Check after Grand Total", {
  input <- c("Product_A", "Check", "Grand Total", "Product_B")

  result <- levels_product_gt_last(input)

  expect_equal(tail(result, 2), c("Grand Total", "Check"))
})

test_that("levels_product_gt_last handles case variations", {
  input <- c("Product_A", "grand total", "GRAND TOTAL", "check")

  result <- levels_product_gt_last(input)

  expect_true("Grand Total" %in% result || "grand total" %in% result)
})

test_that("levels_product_gt_last removes empty/zero values", {
  input <- c("Product_A", "", "0", "0.0", "Grand Total")

  result <- levels_product_gt_last(input)

  expect_false("" %in% result)
  expect_false("0" %in% result)
})

# ============ safe_levels_class Tests ============

test_that("safe_levels_class is alias for levels_product_gt_last", {
  input <- c("Class_A", "Grand Total", "Class_B")

  result1 <- safe_levels_class(input)
  result2 <- levels_product_gt_last(input)

  expect_equal(result1, result2)
})

# ============ Segment Group Levels Tests ============

test_that("levels_segment_group puts NIG first", {
  input <- c("DLI", "NIG", "Other", "Non NIG")

  result <- levels_segment_group(input)

  expect_equal(result[1], "NIG")
  expect_equal(result[2], "Non NIG")
})

test_that("levels_segment_group handles missing segments", {
  input <- c("DLI", "Other")

  result <- levels_segment_group(input)

  expect_true(all(c("DLI", "Other") %in% result))
})

# ============ Join/Bind Utilities Tests ============

test_that("br_rows binds multiple data frames", {
  df1 <- tibble(A = 1:3, B = 4:6)
  df2 <- tibble(A = 7:9, B = 10:12)

  result <- br_rows(list(df1, df2))

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 6)
})

test_that("br_rows handles empty list", {
  result <- br_rows(list())

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("br_rows filters out empty data frames", {
  df1 <- tibble(A = 1:3)
  df2 <- tibble()  # Empty

  result <- br_rows(list(df1, df2))

  expect_equal(nrow(result), 3)
})

test_that(".dedupe_names makes unique column names", {
  df <- tibble(A = 1, A = 2, A = 3, .name_repair = "minimal")

  result <- .dedupe_names(df)

  expect_true(length(unique(names(result))) == ncol(result))
})

test_that(".dedupe_names handles NULL", {
  expect_null(.dedupe_names(NULL))
})

test_that(".dedupe_names handles empty data frame", {
  df <- tibble()

  result <- .dedupe_names(df)

  expect_true(is.data.frame(result))
})
