# ShinyDashAE: Shiny Dashboard for Actual vs Expected Analysis

<!-- badges: start -->
[![R-CMD-check](https://github.com/jp3141github/Shiny_Dash_AE/workflows/R-CMD-check/badge.svg)](https://github.com/jp3141github/Shiny_Dash_AE/actions)
<!-- badges: end -->

An interactive Shiny dashboard for analyzing Actual vs Expected insurance data. Provides comprehensive visualization tools including heatmaps, line charts, waterfall charts, and variance analysis.

## Features

- 📊 **Interactive Visualizations**: 15 different chart types including heatmaps, line charts, waterfall charts, and variance analysis
- 📁 **Flexible Data Import**: Upload CSV or Excel files with automatic column detection
- 🎛️ **Dynamic Filtering**: Filter by product, peril, segment, and time period
- 📥 **Multiple Export Options**: Export results to Excel or ZIP format with one click
- ⌨️ **Keyboard Shortcuts**: Productivity-enhancing shortcuts for common actions
- 🎨 **Customizable**: Configure colors, thresholds, and features via YAML file
- 🔍 **Data Validation**: Built-in data quality checks and validation dashboard
- 📱 **Responsive Design**: Works on desktop and tablet devices

## Installation

### From GitHub (Recommended)

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install ShinyDashAE from GitHub
devtools::install_github("jp3141github/Shiny_Dash_AE")
```

### From Local Source

```r
# Clone the repository
git clone https://github.com/jp3141github/Shiny_Dash_AE.git

# Install from local directory
install.packages("path/to/Shiny_Dash_AE", repos = NULL, type = "source")
```

## Quick Start

```r
# Load the package
library(ShinyDashAE)

# Launch the dashboard
launch_dashboard()
```

That's it! The dashboard will open in your default web browser.

## Usage

### Basic Workflow

1. **Upload Data**: Click "Browse..." to upload your CSV or Excel file
2. **Configure Parameters**: Select Model Type, Projection Date, and Event Type
3. **Run Analysis**: Click "Run Analysis" or press `Ctrl/Cmd+Enter`
4. **View Results**: Explore tables in the Results tab and visualizations in the Charts tab
5. **Export**: Download results as Excel (`Ctrl/Cmd+D`) or ZIP (`Ctrl/Cmd+Shift+Z`)

### Expected Data Format

Your data file should include the following columns:

- `Year`: Numeric year (e.g., 2020, 2021, 2022)
- `Product`: Product name or identifier
- `Peril`: Peril type
- `Measure`: "Paid" or "Incurred"
- `Actual`: Actual values
- `Expected`: Expected values
- `Model_Type`: Model identifier
- `Projection_Date`: Date in DD-MM-YYYY format
- `Event_Type`: Event classification
- `Segment`: Segment identifier (optional)

### Keyboard Shortcuts

- `Ctrl/Cmd+Enter`: Run Analysis
- `Ctrl/Cmd+D`: Download Excel
- `Ctrl/Cmd+Shift+Z`: Download ZIP
- `Ctrl/Cmd+K` or `/`: Open Assistant (if enabled)
- `?`: Show help
- `Esc`: Exit fullscreen chart

### Advanced Options

#### Custom Launch Options

```r
# Launch on specific port
launch_dashboard(port = 8080)

# Launch without opening browser (use RStudio Viewer)
launch_dashboard(launch.browser = FALSE)

# Custom host
launch_dashboard(host = "0.0.0.0", port = 3838)
```

#### Configuration

The dashboard can be customized via the `config.yaml` file in the app directory. Configuration options include:

- Color palettes
- Threshold values
- Feature toggles (assistant modal, static PNG generation)
- Excel export settings
- Chart defaults

## Available Charts

The dashboard includes 15 different visualization types:

### Variance Analysis
1. **Variance Bridge - Total**: Waterfall chart showing variance components
2. **Variance Bridge - Selection**: Filtered variance analysis

### Heatmaps
3. **Product × Year (Paid)**: Heatmap of paid values by product and year
4. **Product × Year (Incurred)**: Heatmap of incurred values by product and year
5. **Paid A-E**: Actual vs Expected heatmap for paid
6. **Incurred A-E**: Actual vs Expected heatmap for incurred
7. **Combined Paid & Incurred**: Integrated A-E heatmap

### Line Charts
8. **Lines - Paid**: Trend lines for paid values
9. **Lines - Incurred**: Trend lines for incurred values

### Waterfall Charts
10. **Waterfall - Paid**: Cumulative changes in paid values
11. **Waterfall - Incurred**: Cumulative changes in incurred values

### Cumulative Charts
12. **Cumulative - Paid**: Running totals for paid
13. **Cumulative - Incurred**: Running totals for incurred

### Custom Analysis
14. **Chart A - AvE Lines**: Specialized A vs E trend analysis
15. **Chart B - Prior Years**: Multi-year comparison by segment

## Data Export

### Excel Export

Results are exported to a multi-sheet Excel workbook including:
- Summary tables
- Detailed results by product and peril
- Pivot tables
- Metadata and filter information

### ZIP Export

ZIP bundles contain:
- All result tables as individual CSV files
- Optional: Static PNG charts (if enabled in config)

### Chart Downloads

Each chart offers two download options:
- **CSV**: Download the underlying data
- **PNG**: Use the Plotly modebar for high-quality export

## Development

### Running Tests

```r
# Install test dependencies
install.packages(c("testthat", "shinytest2"))

# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test file
testthat::test_file("tests/testthat/test-primary-buttons.R")
```

See `tests/TESTING_GUIDE.md` for comprehensive testing documentation.

### Package Structure

```
ShinyDashAE/
├── R/                          # Package functions
│   ├── launch.R               # Main launch functions
│   └── ShinyDashAE-package.R  # Package documentation
├── inst/
│   └── shinyapp/              # Shiny application
│       ├── app.R              # Main app entry point
│       ├── ui.R               # UI definition
│       ├── server.R           # Server logic
│       ├── global.R           # Global setup
│       ├── config.yaml        # Configuration
│       └── R/                 # App modules (32 files)
├── tests/                      # Test suite (120+ tests)
├── man/                        # Documentation
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Package exports
└── README.md                   # This file
```

## Requirements

### R Version
- R >= 4.0.0

### Dependencies

**Core:**
- shiny (>= 1.7.0)
- bslib
- DT

**Data Manipulation:**
- dplyr
- tidyr
- purrr
- tibble

**I/O:**
- readr
- readxl
- openxlsx
- fs
- zip
- yaml

**Visualization:**
- ggplot2
- plotly
- scales

**Utilities:**
- lubridate
- glue

## Troubleshooting

### Common Issues

**Problem**: Package won't install
**Solution**: Ensure all dependencies are installed first
```r
install.packages(c("shiny", "bslib", "DT", "dplyr", "tidyr", "readr",
                   "readxl", "lubridate", "purrr", "fs", "glue",
                   "ggplot2", "plotly", "openxlsx", "zip", "scales"))
```

**Problem**: App won't launch
**Solution**: Check that the package installed correctly
```r
system.file("shinyapp", package = "ShinyDashAE")
# Should return a valid path
```

**Problem**: Data won't upload
**Solution**: Verify your file has the required columns
```r
# Check your data structure
str(your_data)
```

**Problem**: Analysis fails with function not found error
**Solution**: Ensure you're using the latest version from GitHub

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation
- Run `testthat::test_dir("tests/testthat")` before submitting

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use ShinyDashAE in your research or work, please cite:

```
@software{shinydashae,
  title = {ShinyDashAE: Shiny Dashboard for Actual vs Expected Analysis},
  author = {{ShinyDashAE Contributors}},
  year = {2024},
  url = {https://github.com/jp3141github/Shiny_Dash_AE}
}
```

## Support

- 📖 Documentation: See function help pages with `?launch_dashboard`
- 🐛 Bug Reports: [GitHub Issues](https://github.com/jp3141github/Shiny_Dash_AE/issues)
- 💬 Questions: Open a [GitHub Discussion](https://github.com/jp3141github/Shiny_Dash_AE/discussions)
- 📧 Email: [Contact maintainer](mailto:your.email@example.com)

## Acknowledgments

Built with:
- [Shiny](https://shiny.rstudio.com/) by RStudio
- [Plotly](https://plotly.com/r/) for interactive visualizations
- [DT](https://rstudio.github.io/DT/) for interactive tables
- [bslib](https://rstudio.github.io/bslib/) for modern UI theming

## Changelog

### Version 1.0.0 (2024)
- Initial package release
- 15 chart types
- Excel and ZIP export
- Comprehensive test suite (120+ tests)
- Full documentation
- Keyboard shortcuts
- Configurable via YAML

---

**Made with ❤️ by the ShinyDashAE team**
