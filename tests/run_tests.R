# tests/run_tests.R — Test runner script for ShinyDashAE

# ==============================================================================
# ShinyDashAE Test Runner
# ==============================================================================
#
# Usage:
#   source("tests/run_tests.R")  # From app root directory
#   OR
#   Rscript tests/run_tests.R     # From command line
#
# Options:
#   Run specific test files by setting TEST_FILES environment variable:
#   Sys.setenv(TEST_FILES = "test-utils-core.R,test-builders.R")
#
# ==============================================================================

cat("\n")
cat("==========================================================\n")
cat("         ShinyDashAE Test Suite\n")
cat("==========================================================\n")
cat("\n")

# Set working directory to app root if running from tests/
if (basename(getwd()) == "tests") {
  setwd("..")
}

# Store start time
start_time <- Sys.time()

# Check required packages
required_packages <- c("testthat", "dplyr", "tidyr", "tibble", "lubridate",
                       "stringr", "purrr", "ggplot2", "plotly", "openxlsx")

missing_packages <- setdiff(required_packages, rownames(installed.packages()))

if (length(missing_packages) > 0) {
  cat("Missing required packages:\n")
  cat(paste(" -", missing_packages, collapse = "\n"), "\n\n")
  cat("Install with:\n")
  cat(sprintf('install.packages(c("%s"))\n', paste(missing_packages, collapse = '", "')))
  stop("Please install missing packages before running tests.")
}

# Load testthat
library(testthat)

# Source app R files (excluding server modules that require Shiny context)
cat("Loading app code...\n")
r_files <- list.files("R", pattern = "^\\d+.*\\.R$", full.names = TRUE)
r_files <- r_files[!grepl("70_|71_|72_|73_|74_|75_|76_|77_", r_files)]

# Create mock showNotification for non-Shiny context
showNotification <- function(message, type = "default", duration = 5) {
  invisible(NULL)
}

for (f in sort(r_files)) {
  tryCatch(
    source(f),
    error = function(e) {
      cat(sprintf("  Warning: Could not source %s: %s\n", basename(f), e$message))
    }
  )
}

cat("App code loaded.\n\n")

# Get test files
test_dir <- "tests/testthat"
test_files <- Sys.getenv("TEST_FILES", "")

if (nzchar(test_files)) {
  # Run specific test files
  test_files <- trimws(strsplit(test_files, ",")[[1]])
  test_files <- file.path(test_dir, test_files)
  test_files <- test_files[file.exists(test_files)]
} else {
  # Run all test files (exclude shiny-app tests by default unless specified)
  test_files <- list.files(test_dir, pattern = "^test-.*\\.R$", full.names = TRUE)

  # Skip shinytest2 tests unless explicitly requested
  if (Sys.getenv("RUN_SHINY_TESTS", "false") != "true") {
    test_files <- test_files[!grepl("test-shiny-app\\.R$", test_files)]
    cat("Note: Skipping shinytest2 tests. Set RUN_SHINY_TESTS=true to include.\n\n")
  }
}

cat(sprintf("Running %d test file(s):\n", length(test_files)))
for (f in test_files) {
  cat(sprintf("  - %s\n", basename(f)))
}
cat("\n")

# Run tests
cat("==========================================================\n")
cat("                    Test Results\n")
cat("==========================================================\n\n")

results <- test_dir(
  test_dir,
  filter = if (nzchar(Sys.getenv("TEST_FILES"))) NULL else "^test-(?!shiny-app)",
  reporter = "summary",
  stop_on_failure = FALSE
)

# Print summary
cat("\n")
cat("==========================================================\n")
cat("                    Summary\n")
cat("==========================================================\n\n")

# Calculate elapsed time
elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

if (inherits(results, "testthat_results")) {
  n_pass <- sum(vapply(results, function(x) x$passed, integer(1)))
  n_fail <- sum(vapply(results, function(x) x$failed, integer(1)))
  n_skip <- sum(vapply(results, function(x) x$skipped, integer(1)))
  n_warn <- sum(vapply(results, function(x) x$warning, integer(1)))

  cat(sprintf("  Passed:   %d\n", n_pass))
  cat(sprintf("  Failed:   %d\n", n_fail))
  cat(sprintf("  Skipped:  %d\n", n_skip))
  cat(sprintf("  Warnings: %d\n", n_warn))
  cat(sprintf("\n  Total time: %.1f seconds\n", elapsed))

  if (n_fail > 0) {
    cat("\n  Status: FAILED\n")
    quit(status = 1)
  } else {
    cat("\n  Status: PASSED\n")
    quit(status = 0)
  }
} else {
  cat(sprintf("  Total time: %.1f seconds\n", elapsed))
  cat("\n  Tests completed. Check output above for details.\n")
}
