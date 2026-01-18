# install_packages.R - Install all required R packages for AvsE Shiny Dashboard
# Run with: Rscript install_packages.R

packages <- c(
  "shiny",
  "bslib",
  "DT",
  "readr",
  "readxl",
  "dplyr",
  "tidyr",
  "stringr",
  "lubridate",
  "purrr",
  "rlang",
  "fs",
  "glue",
  "ggplot2",
  "openxlsx",
  "zip",
  "scales",
  "plotly",
  "tibble"
)

# Check which packages are not installed
missing <- packages[!(packages %in% installed.packages()[, "Package"])]

if (length(missing) > 0) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

# Verify all packages can be loaded
message("\nVerifying package loading...")
for (pkg in packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message("  ✓ ", pkg)
  } else {
    message("  ✗ ", pkg, " - FAILED TO LOAD")
  }
}

message("\nDone. You can now run the app with: Rscript app.R")
