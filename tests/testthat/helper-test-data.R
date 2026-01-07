# tests/testthat/helper-test-data.R — Test data and helper functions

# Load required packages for tests
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(lubridate)
  library(stringr)
  library(purrr)
  library(ggplot2)
  library(plotly)
})

# Source all R files from the app
app_dir <- file.path(dirname(dirname(getwd())), "R")
if (!dir.exists(app_dir)) {
  app_dir <- file.path(getwd(), "R")
}
if (!dir.exists(app_dir)) {
  app_dir <- file.path(dirname(getwd()), "R")
}

# Try multiple paths for sourcing R files
possible_paths <- c(
  file.path(getwd(), "R"),
  file.path(dirname(getwd()), "R"),
  file.path(dirname(dirname(getwd())), "R"),
  "/home/user/Claude_Manus_AvsE_Shiny_Dash_app/R"
)

for (p in possible_paths) {
  if (dir.exists(p)) {
    app_dir <- p
    break
  }
}

if (dir.exists(app_dir)) {
  r_files <- list.files(app_dir, pattern = "^\\d+.*\\.R$", full.names = TRUE)
  r_files <- r_files[!grepl("70_|71_|72_|73_|74_|75_|76_|77_", r_files)]  # Exclude server modules
  for (f in sort(r_files)) {
    tryCatch(source(f), error = function(e) message("Skipping ", basename(f), ": ", e$message))
  }
}

# Create mock showNotification for non-Shiny context
if (!exists("showNotification")) {
  showNotification <- function(message, type = "default", duration = 5) {
    # Silent in test context
    invisible(NULL)
  }
}

#' Create sample test data for A v E analysis
#' @param n_rows Number of rows to generate
#' @param years Vector of years to include
#' @param products Vector of product names
#' @param perils Vector of peril names
#' @return A tibble with test data
create_test_data <- function(n_rows = 100,
                              years = 2020:2024,
                              products = c("Product_A", "Product_B", "Product_C"),
                              perils = c("Peril_1", "Peril_2", "Peril_3")) {
  set.seed(42)

  tibble(
    `Accident Year` = sample(years, n_rows, replace = TRUE),
    Product = sample(products, n_rows, replace = TRUE),
    Peril = sample(perils, n_rows, replace = TRUE),
    Measure = sample(c("Paid", "Incurred"), n_rows, replace = TRUE),
    Actual = runif(n_rows, 100000, 1000000),
    Expected = runif(n_rows, 100000, 1000000),
    `Current or Prior` = sample(c("PY", "CY"), n_rows, replace = TRUE),
    Segment = sample(c("NIG", "DLI", "Other"), n_rows, replace = TRUE),
    `Segment (Group)` = sample(c("NIG", "Non NIG"), n_rows, replace = TRUE),
    `Model Type` = sample(c("Model_A", "Model_B"), n_rows, replace = TRUE),
    ProjectionDate = sample(c("01-01-2024", "01-07-2024"), n_rows, replace = TRUE),
    `Event / Non-Event` = sample(c("Event", "Non-Event"), n_rows, replace = TRUE)
  ) %>%
    mutate(`A - E` = Actual - Expected)
}

#' Create minimal valid test data
#' @return A tibble with minimal required columns
create_minimal_test_data <- function() {
  tibble(
    `Accident Year` = c(2023, 2023, 2024, 2024),
    Product = c("Prod_A", "Prod_A", "Prod_B", "Prod_B"),
    Peril = c("Peril_1", "Peril_1", "Peril_2", "Peril_2"),
    Measure = c("Paid", "Incurred", "Paid", "Incurred"),
    Actual = c(1000, 1500, 2000, 2500),
    Expected = c(900, 1400, 1800, 2300),
    `Current or Prior` = c("CY", "CY", "PY", "PY"),
    Segment = c("NIG", "NIG", "DLI", "DLI")
  ) %>%
    mutate(`A - E` = Actual - Expected)
}

#' Create data with edge cases
#' @return A tibble with edge case data
create_edge_case_data <- function() {
  tibble(
    `Accident Year` = c(2023, 2024, NA, 2023, 2024),
    Product = c("Prod_A", "Prod_B", "Prod_C", "", "Prod_A"),
    Peril = c("Peril_1", "", NA, "Peril_2", "Peril_1"),
    Measure = c("Paid", "Incurred", "Paid", "paid", "INCURRED"),
    Actual = c(1000, NA, 0, -500, 2000),
    Expected = c(900, 1000, 0, -400, NA),
    `Current or Prior` = c("CY", "Prior", "CURRENT", NA, "py"),
    Segment = c("NIG", "nig", NA, "", "DLI")
  )
}

#' Create data for chart tests
#' @return A tibble optimized for chart testing
create_chart_test_data <- function() {
  years <- 2020:2024
  products <- c("Product_A", "Product_B")
  perils <- c("Peril_1", "Peril_2")

  expand_grid(
    `Accident Year` = years,
    Product = products,
    Peril = perils,
    Measure = c("Paid", "Incurred")
  ) %>%
    mutate(
      Actual = 100000 + `Accident Year` * 100 + as.numeric(factor(Product)) * 1000,
      Expected = Actual * runif(n(), 0.9, 1.1),
      `A - E` = Actual - Expected,
      `Current or Prior` = if_else(`Accident Year` == max(years), "CY", "PY"),
      Segment = if_else(Product == "Product_A", "NIG", "DLI"),
      `Segment (Group)` = if_else(Segment == "NIG", "NIG", "Non NIG")
    )
}

#' Create data with unicode/special characters
#' @return A tibble with special character handling
create_unicode_test_data <- function() {
  tibble(
    `Accident Year` = c(2023, 2024),
    Product = c("Product−A", "Product–B"),  # Unicode minus/dash
    Peril = c("Peril 1", "Peril 2"),
    Measure = c("Paid", "Incurred"),
    Actual = c("£1,000,000", "(500,000)"),  # Currency, brackets
    Expected = c("900 000", "−400000"),  # Non-breaking space, unicode minus
    `Current or Prior` = c("CY", "PY")
  )
}

#' Create data for filter tests
#' @return A tibble with varied filter conditions
create_filter_test_data <- function() {
  tibble(
    `Accident Year` = rep(2020:2024, each = 4),
    Product = rep(c("Prod_A", "Prod_B"), 10),
    Peril = rep(c("Peril_1", "Peril_2"), 10),
    Measure = rep(c("Paid", "Paid", "Incurred", "Incurred"), 5),
    Actual = runif(20, 100000, 500000),
    Expected = runif(20, 100000, 500000),
    `Current or Prior` = c(rep("PY", 16), rep("CY", 4)),
    Segment = rep(c("NIG", "NIG", "DLI", "Other"), 5),
    `Model Type` = rep(c("Model_A", "Model_B"), 10),
    ProjectionDate = rep(c("01-01-2024", "01-07-2024"), 10),
    `Event / Non-Event` = rep(c("Event", "Non-Event"), 10)
  ) %>%
    mutate(`A - E` = Actual - Expected)
}

#' Assert data frame structure
#' @param df Data frame to check
#' @param required_cols Vector of required column names
assert_df_structure <- function(df, required_cols) {
  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0)
  for (col in required_cols) {
    expect_true(col %in% names(df), info = paste("Missing column:", col))
  }
}

#' Assert numeric column properties
#' @param vec Numeric vector to check
#' @param allow_na Allow NA values
#' @param allow_negative Allow negative values
assert_numeric_valid <- function(vec, allow_na = TRUE, allow_negative = TRUE) {
  expect_true(is.numeric(vec))
  if (!allow_na) {
    expect_true(!any(is.na(vec)))
  }
  if (!allow_negative) {
    expect_true(all(vec >= 0, na.rm = TRUE))
  }
}

#' Skip test if not in Shiny context
skip_if_not_shiny <- function() {
  if (!shiny::isRunning()) {
    skip("Not running in Shiny context")
  }
}

#' Create mock Shiny session
create_mock_session <- function() {
  list(
    sendCustomMessage = function(type, message) invisible(NULL),
    sendInputMessage = function(inputId, message) invisible(NULL),
    onFlushed = function(fun, once = TRUE) invisible(NULL),
    ns = function(id) id,
    userData = new.env(parent = emptyenv())
  )
}
