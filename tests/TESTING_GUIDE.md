# ShinyDashAE Testing Guide

## Overview

This guide covers the comprehensive test suite for ShinyDashAE, including unit tests, integration tests, and end-to-end Shiny application tests.

## Test Structure

```
tests/
├── testthat.R              # testthat entry point
├── run_tests.R             # Standalone test runner script
├── TESTING_GUIDE.md        # This file
└── testthat/
    ├── helper-test-data.R  # Test data generators and helpers
    ├── test-utils-core.R   # Core utility function tests
    ├── test-utils-types.R  # Type conversion tests
    ├── test-utils-filters.R# Filter function tests
    ├── test-builders.R     # Data builder tests
    ├── test-charts.R       # Chart generation tests
    ├── test-export.R       # Excel export tests
    ├── test-orchestration.R# Integration tests
    └── test-shiny-app.R    # shinytest2 E2E tests
```

## Running Tests

### Quick Start

```r
# From the app root directory
source("tests/run_tests.R")
```

### Using testthat Directly

```r
# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test file
testthat::test_file("tests/testthat/test-utils-core.R")

# Run tests matching a pattern
testthat::test_dir("tests/testthat", filter = "utils")
```

### Running Shiny App Tests

Shiny app tests require `shinytest2` and a Chrome browser:

```r
# Install shinytest2 if needed
install.packages("shinytest2")

# Run shiny tests explicitly
Sys.setenv(RUN_SHINY_TESTS = "true")
source("tests/run_tests.R")

# Or use shinytest2 directly
shinytest2::test_app(".")
```

### Command Line

```bash
# Run all tests
Rscript tests/run_tests.R

# Run specific tests
TEST_FILES="test-utils-core.R,test-builders.R" Rscript tests/run_tests.R

# Include shinytest2 tests
RUN_SHINY_TESTS=true Rscript tests/run_tests.R
```

## Test Categories

### 1. Unit Tests

#### Utils Core (`test-utils-core.R`)
- `%||%` operator null coalescing
- `scalar_or()` scalar validation
- `._dbg()` debug output
- `dbg_rows()` data frame debugging
- `is_raw_sheet_name()` sheet name detection

#### Utils Types (`test-utils-types.R`)
- `to_float()` numeric conversion
  - Currency handling (£, commas)
  - Bracketed negatives
  - Unicode minus characters
  - Non-breaking spaces
- `parse_projection_date_dateonly()` date parsing
  - Multiple date formats
  - Excel serial dates
  - 8-digit dates
- `coerce_types()` data frame type coercion
  - Measure normalization
  - Year clamping
  - Column derivation

#### Utils Filters (`test-utils-filters.R`)
- `norm_key()` text normalization
- `map_event()` event type mapping
- `first_present_col()` column detection
- `apply_filters()` data filtering
- `ensure_columns()` column validation

### 2. Builder Tests (`test-builders.R`)

- `py_cy_split()` Prior/Current year splitting
- `three_block_ave_table()` table construction
- `append_grand_total_row_pvt()` grand total addition
- `pivot_product_peril_by_year()` pivot table creation
- `build_paid_ave()`, `build_incurred_ave()` A-E tables
- `build_paid_a()`, `build_paid_e()` actuals/expected tables
- `build_total_summary()` summary statistics

### 3. Chart Tests (`test-charts.R`)

- `year_axis()` axis configuration
- `series_pack()` data series preparation
- `align_series()` series alignment
- Heatmap generation
- Line chart data preparation
- Waterfall chart data
- Variance calculations
- Cumulative aggregations

### 4. Export Tests (`test-export.R`)

- `build_summary_sheet()` summary generation
- `write_excel()` Excel file creation
  - Sheet creation
  - Style application
  - Special character handling
  - Infinite value handling

### 5. Integration Tests (`test-orchestration.R`)

- `build_all_tables()` complete output generation
- Product exclusion
- Filter application
- NIG/Non-NIG segment splits
- Data integrity verification
- Performance on large datasets

### 6. Shiny App Tests (`test-shiny-app.R`)

- App launch
- UI element presence
- File upload (CSV/Excel)
- Analysis execution
- Tab navigation
- Download functionality
- Filter interactions
- Keyboard shortcuts
- Error handling
- Chart rendering

## Test Data Generators

The `helper-test-data.R` file provides:

```r
# Standard test data (100 rows)
create_test_data(n_rows = 100)

# Minimal valid data (4 rows)
create_minimal_test_data()

# Edge cases (NAs, empty strings, invalid values)
create_edge_case_data()

# Chart-optimized data (full year/product/peril grid)
create_chart_test_data()

# Unicode/special characters
create_unicode_test_data()

# Filter testing data
create_filter_test_data()
```

## Writing New Tests

### Test File Template

```r
# tests/testthat/test-feature.R

test_that("function does expected thing", {
  # Arrange
  df <- create_test_data(50)

  # Act
  result <- my_function(df)

  # Assert
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), expected_rows)
})

test_that("function handles edge cases", {
  # Test NULL input
  expect_null(my_function(NULL))

  # Test empty data
  result <- my_function(tibble())
  expect_equal(nrow(result), 0)
})
```

### Best Practices

1. **Use descriptive test names**: `test_that("to_float handles currency formatting")`

2. **Test edge cases**: NULL, empty, NA, special characters

3. **Use helper functions**: Reuse `create_test_data()` etc.

4. **Check structure and content**: Verify both data frame structure and values

5. **Skip appropriately**: Use `skip_if_not_installed()`, `skip_on_ci()`

6. **Clean up resources**: Use `on.exit()` for temp files

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2

      - uses: r-lib/actions/setup-r-dependencies@v2

      - name: Run tests
        run: |
          Rscript tests/run_tests.R

      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: tests/testthat/*.log
```

## Coverage

To generate test coverage reports:

```r
# Install covr
install.packages("covr")

# Generate coverage report
cov <- covr::package_coverage(
  path = ".",
  type = "tests"
)

# View report
covr::report(cov)

# Get coverage percentage
covr::percent_coverage(cov)
```

## Troubleshooting

### Common Issues

1. **"showNotification not found"**
   - The helper file provides a mock. Ensure `helper-test-data.R` is loaded.

2. **"Package X not installed"**
   - Install missing packages: `install.packages("package_name")`

3. **shinytest2 fails to start**
   - Ensure Chrome/Chromium is installed
   - Check: `chromote::find_chrome()`

4. **Tests timeout**
   - Increase timeout in `AppDriver$new(timeout = 60000)`
   - Check for infinite loops in app code

5. **Date parsing tests fail**
   - Locale differences may affect date formats
   - Use explicit date objects: `as.Date("2024-01-01")`

### Debug Mode

```r
# Enable debug output
options(ave.debug = TRUE)

# Run single test
testthat::test_file("tests/testthat/test-utils-core.R")

# Enable verbose shinytest2
Sys.setenv(SHINYTEST_HEADLESS = "false")
```

## Test Maintenance

- Run tests before each commit
- Add tests for new features
- Update tests when behavior changes
- Review skipped tests periodically
- Monitor test execution time

---

**Questions?** Open an issue at https://github.com/jp3141github/Shiny_Dash_AE/issues
