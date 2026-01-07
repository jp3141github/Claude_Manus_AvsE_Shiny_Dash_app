# Installation Guide for ShinyDashAE

## Quick Install

```r
# Install from GitHub (recommended)
devtools::install_github("jp3141github/Shiny_Dash_AE")
```

## Detailed Installation Instructions

### Step 1: Install R and RStudio

If you haven't already:

1. **Install R** (>= 4.0.0): https://cran.r-project.org/
2. **Install RStudio** (recommended): https://posit.co/download/rstudio-desktop/

### Step 2: Install devtools

```r
install.packages("devtools")
```

### Step 3: Install ShinyDashAE

#### Option A: Install from GitHub (Recommended)

```r
devtools::install_github("jp3141github/Shiny_Dash_AE")
```

This will automatically install all dependencies.

#### Option B: Install from Source

1. Download the repository:
```bash
git clone https://github.com/jp3141github/Shiny_Dash_AE.git
```

2. Install from local directory:
```r
devtools::install("path/to/Shiny_Dash_AE")
```

#### Option C: Install from Package File

If you have a `.tar.gz` package file:

```r
install.packages("path/to/ShinyDashAE_1.0.0.tar.gz", repos = NULL, type = "source")
```

### Step 4: Verify Installation

```r
library(ShinyDashAE)
?launch_dashboard
```

If help documentation appears, installation was successful!

### Step 5: Launch the Dashboard

```r
launch_dashboard()
```

## Dependency Installation

### Automatic (Recommended)

Dependencies are automatically installed when you install the package via `devtools::install_github()`.

### Manual

If you need to install dependencies manually:

```r
# Core dependencies
install.packages(c(
  "shiny",
  "bslib",
  "DT",
  "dplyr",
  "tidyr",
  "readr",
  "readxl",
  "lubridate",
  "purrr",
  "fs",
  "glue",
  "ggplot2",
  "plotly",
  "openxlsx",
  "zip",
  "scales",
  "tibble",
  "yaml"
))

# Optional: For testing
install.packages(c("testthat", "shinytest2"))

# Optional: For vignettes
install.packages(c("knitr", "rmarkdown"))
```

## Troubleshooting

### Problem: devtools not available

**Solution:**
```r
install.packages("devtools")
```

### Problem: Compilation errors on Windows

**Solution:** Install Rtools
1. Download Rtools: https://cran.r-project.org/bin/windows/Rtools/
2. Install with default settings
3. Restart RStudio
4. Try installation again

### Problem: Compilation errors on Mac

**Solution:** Install Xcode Command Line Tools
```bash
xcode-select --install
```

### Problem: Compilation errors on Linux

**Solution:** Install development libraries

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libfreetype6-dev \
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev
```

**CentOS/RHEL:**
```bash
sudo yum install -y \
  libcurl-devel \
  openssl-devel \
  libxml2-devel \
  fontconfig-devel \
  harfbuzz-devel \
  fribidi-devel \
  freetype-devel \
  libpng-devel \
  libtiff-devel \
  libjpeg-turbo-devel
```

### Problem: Package installation succeeds but app won't launch

**Solution 1:** Check package installation
```r
system.file("shinyapp", package = "ShinyDashAE")
# Should return a valid path like: "/path/to/R/library/ShinyDashAE/shinyapp"
```

**Solution 2:** Reinstall package
```r
remove.packages("ShinyDashAE")
devtools::install_github("jp3141github/Shiny_Dash_AE")
```

**Solution 3:** Check for missing dependencies
```r
# List all package dependencies
tools::package_dependencies("ShinyDashAE", recursive = TRUE)
```

### Problem: Slow installation

**Cause:** Large number of dependencies

**Solutions:**
- Use binary packages (default on Windows/Mac)
- Install from CRAN mirror close to your location
- Use `install.packages()` with `type = "binary"` where available

### Problem: Permission errors during installation

**Windows:**
- Run RStudio as Administrator
- Or install to user library: `.libPaths()`

**Mac/Linux:**
```r
# Install to user library (no sudo required)
install.packages("devtools", lib = "~/R/library")
.libPaths("~/R/library")
```

## Update Package

To update to the latest version:

```r
# Remove old version
remove.packages("ShinyDashAE")

# Install latest from GitHub
devtools::install_github("jp3141github/Shiny_Dash_AE")
```

Or with `force = TRUE`:

```r
devtools::install_github("jp3141github/Shiny_Dash_AE", force = TRUE)
```

## Offline Installation

If you need to install on a machine without internet:

1. **On a machine with internet**, download the package and all dependencies:
```r
download.packages(
  "ShinyDashAE",
  destdir = "~/ShinyDashAE_offline",
  type = "source"
)

# Download dependencies
deps <- tools::package_dependencies("ShinyDashAE", recursive = TRUE)
download.packages(
  unlist(deps),
  destdir = "~/ShinyDashAE_offline",
  type = "source"
)
```

2. **Transfer the `ShinyDashAE_offline` folder** to the offline machine

3. **On the offline machine**, install:
```r
# Install dependencies first
install.packages(
  list.files("~/ShinyDashAE_offline", pattern = "^(?!ShinyDashAE)", perl = TRUE, full.names = TRUE),
  repos = NULL,
  type = "source"
)

# Install ShinyDashAE
install.packages(
  "~/ShinyDashAE_offline/ShinyDashAE_1.0.0.tar.gz",
  repos = NULL,
  type = "source"
)
```

## Building from Source

To build the package yourself:

```bash
# Clone repository
git clone https://github.com/jp3141github/Shiny_Dash_AE.git
cd Shiny_Dash_AE

# Build package
R CMD build .

# Check package
R CMD check ShinyDashAE_*.tar.gz

# Install
R CMD INSTALL ShinyDashAE_*.tar.gz
```

Or in R:

```r
devtools::build()
devtools::check()
devtools::install()
```

## System Requirements

- **R**: >= 4.0.0
- **RAM**: 2GB minimum, 4GB+ recommended for large datasets
- **Disk Space**: ~100MB for package and dependencies
- **Internet**: Required for initial installation (unless offline method used)
- **Browser**: Modern browser (Chrome, Firefox, Edge, Safari)

## Next Steps

After successful installation:

1. Read the vignette: `vignette("getting-started", package = "ShinyDashAE")`
2. Launch the dashboard: `launch_dashboard()`
3. Explore the documentation: `?ShinyDashAE`

## Support

If you encounter issues not covered here:

- Check: https://github.com/jp3141github/Shiny_Dash_AE/issues
- Ask: https://github.com/jp3141github/Shiny_Dash_AE/discussions
- Email: [Maintainer email]
