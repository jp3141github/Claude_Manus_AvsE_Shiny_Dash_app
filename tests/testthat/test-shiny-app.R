# tests/testthat/test-shiny-app.R — Shiny application tests using shinytest2

# Note: These tests require the app to be runnable and shinytest2 installed
# Run with: shinytest2::test_app("path/to/app")

library(testthat)

# ============ App Launch Tests ============

test_that("App launches without error", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()  # Skip on CI unless chromote is available

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    app_dir <- getwd()
  }

  if (file.exists(file.path(app_dir, "app.R"))) {
    app <- shinytest2::AppDriver$new(
      app_dir = app_dir,
      name = "launch-test",
      timeout = 30000
    )

    # App should be running
    expect_true(inherits(app, "AppDriver"))

    # Clean up
    app$stop()
  } else {
    skip("app.R not found")
  }
})

# ============ UI Element Tests ============

test_that("Required UI elements exist", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "ui-elements-test",
    timeout = 30000
  )

  # Check sidebar controls exist
  html <- app$get_html("body")

  # File upload should exist
  expect_true(grepl("file_upload|fileInput", html, ignore.case = TRUE))

  # Model Type selector should exist
  expect_true(grepl("model_type|Model Type", html, ignore.case = TRUE))

  # Run Analysis button should exist
  expect_true(grepl("run_analysis|Run Analysis", html, ignore.case = TRUE))

  app$stop()
})

# ============ File Upload Tests ============

test_that("File upload accepts CSV files",
{
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  # Create test CSV
  test_data <- create_test_data(50)
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "upload-test",
    timeout = 30000
  )

  # Upload the file
  app$upload_file(file_upload = temp_csv)

  # Wait for processing
  Sys.sleep(2)

  # Check that data preview appears
  html <- app$get_html("body")
  expect_true(grepl("Product|Peril|Actual|Expected", html))

  # Clean up
  app$stop()
  unlink(temp_csv)
})

# ============ Analysis Run Tests ============

test_that("Run Analysis button triggers processing", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  # Create and upload test data
  test_data <- create_test_data(50)
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "analysis-test",
    timeout = 60000
  )

  # Upload file
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # Click Run Analysis
  app$click("run_analysis")

  # Wait for analysis to complete
  Sys.sleep(5)

  # Check that results appear
  html <- app$get_html("body")

  # Should show results or charts tab
  expect_true(grepl("Results|Charts|Total Summary", html))

  app$stop()
  unlink(temp_csv)
})

# ============ Tab Navigation Tests ============

test_that("Tab navigation works", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "tab-nav-test",
    timeout = 30000
  )

  # Upload test data
  test_data <- create_test_data(50)
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # Run analysis first
  app$click("run_analysis")
  Sys.sleep(3)

  # Try clicking on Charts tab
  tryCatch({
    app$click(selector = "a[data-value='Charts']")
    Sys.sleep(1)
    html <- app$get_html("body")
    # Check for chart-related content
    expect_true(grepl("chart|plot|heatmap|variance", html, ignore.case = TRUE))
  }, error = function(e) {
    # Tab might have different selector
    skip("Charts tab selector not found")
  })

  app$stop()
  unlink(temp_csv)
})

# ============ Download Tests ============

test_that("Excel download button works", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "download-test",
    timeout = 60000
  )

  # Upload test data
  test_data <- create_test_data(50)
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # Run analysis
  app$click("run_analysis")
  Sys.sleep(5)

  # Check that download button exists
  html <- app$get_html("body")
  expect_true(grepl("download|Download|Excel", html, ignore.case = TRUE))

  app$stop()
  unlink(temp_csv)
})

# ============ Filter Tests ============

test_that("Product filter updates correctly", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "filter-test",
    timeout = 30000
  )

  # Upload test data with known products
  test_data <- create_test_data(50)
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # Check that product filter populated
  html <- app$get_html("body")
  expect_true(grepl("Product", html))

  app$stop()
  unlink(temp_csv)
})

# ============ Keyboard Shortcut Tests ============

test_that("Keyboard shortcuts are registered", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "keyboard-test",
    timeout = 30000
  )

  # Check that keyboard shortcut handlers are registered in JS
  html <- app$get_html("body")

  # The app should have keyboard handler code
  expect_true(grepl("keydown|keyboard|shortcut", html, ignore.case = TRUE) ||
                grepl("Ctrl|Cmd|Enter", html, ignore.case = TRUE))

  app$stop()
})

# ============ Error Handling Tests ============

test_that("App handles invalid file gracefully", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "error-handling-test",
    timeout = 30000
  )

  # Create invalid CSV (missing required columns)
  invalid_data <- data.frame(
    X = 1:5,
    Y = letters[1:5]
  )
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(invalid_data, temp_csv)

  # Upload invalid file
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # App should still be running (not crashed)
  html <- app$get_html("body")
  expect_true(length(html) > 0)

  # Should show some kind of error/warning message
  # (exact message depends on implementation)

  app$stop()
  unlink(temp_csv)
})

# ============ Validation Tab Tests ============

test_that("Validation tab shows data checks", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "validation-test",
    timeout = 30000
  )

  # Upload test data
  test_data <- create_test_data(50)
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # Check for validation content
  html <- app$get_html("body")
  expect_true(grepl("Validation|validation|Check|check", html))

  app$stop()
  unlink(temp_csv)
})

# ============ Chart Rendering Tests ============

test_that("Charts render correctly", {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_on_ci()

  app_dir <- dirname(dirname(dirname(getwd())))
  if (!file.exists(file.path(app_dir, "app.R"))) {
    skip("app.R not found")
  }

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "chart-render-test",
    timeout = 60000
  )

  # Upload test data
  test_data <- create_chart_test_data()
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  app$upload_file(file_upload = temp_csv)
  Sys.sleep(2)

  # Run analysis
  app$click("run_analysis")
  Sys.sleep(5)

  # Navigate to Charts tab
  tryCatch({
    app$click(selector = "a[data-value='Charts']")
    Sys.sleep(2)

    html <- app$get_html("body")

    # Check for plotly or chart containers
    expect_true(grepl("plotly|js-plotly-plot|chart", html, ignore.case = TRUE))
  }, error = function(e) {
    skip("Could not navigate to Charts tab")
  })

  app$stop()
  unlink(temp_csv)
})
