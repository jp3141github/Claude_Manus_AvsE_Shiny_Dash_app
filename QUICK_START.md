# ShinyDashAE Quick Start Guide

## Installation (30 seconds)

```r
devtools::install_github("jp3141github/Shiny_Dash_AE")
```

## Launch (5 seconds)

```r
library(ShinyDashAE)
launch_dashboard()
```

## Basic Usage (2 minutes)

1. **Upload**: Click "Browse..." → Select CSV/Excel → See preview
2. **Configure**: Set Model Type, Projection Date, Event Type
3. **Analyze**: Click "Run Analysis" (or `Ctrl/Cmd+Enter`)
4. **View**: Switch between Results and Charts tabs
5. **Export**: Click "Download Excel" (or `Ctrl/Cmd+D`)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl/Cmd+Enter` | Run Analysis |
| `Ctrl/Cmd+D` | Download Excel |
| `Ctrl/Cmd+Shift+Z` | Download ZIP |
| `Ctrl/Cmd+K` | Open Assistant |

## Required Data Columns

Your CSV/Excel must have:
- `Year`, `Product`, `Peril`, `Measure`
- `Actual`, `Expected`
- `Model_Type`, `Projection_Date`, `Event_Type`

## Example Data

```r
data.frame(
  Year = 2023,
  Product = "Product_A",
  Peril = "Peril_1",
  Measure = "Paid",
  Actual = 1000000,
  Expected = 950000,
  Model_Type = "Model_A",
  Projection_Date = "01-01-2023",
  Event_Type = "Non-Event",
  Segment = "NIG"
)
```

## Help

- Documentation: `?launch_dashboard`
- Vignette: `vignette("getting-started", package = "ShinyDashAE")`
- Issues: https://github.com/jp3141github/Shiny_Dash_AE/issues

## Common Issues

**App won't launch?**
```r
# Check installation
system.file("shinyapp", package = "ShinyDashAE")
```

**Upload fails?**
- Check file has required columns
- Verify date format: DD-MM-YYYY

**Analysis fails?**
- Select Model Type and Projection Date
- Check data preview for errors

## Next Steps

- Try all 15 chart types
- Use filters to focus analysis
- Export to Excel for reporting
- Customize `config.yaml` settings

---

**Full Documentation**: See README.md
**Installation Guide**: See INSTALL.md
**Testing Guide**: See tests/TESTING_GUIDE.md
