# R/77_server_chart_downloads.R — Chart download handlers

register_chart_downloads_server <- function(input, output, session, results_obj) {

  # ReactiveValues to store chart data for CSV downloads
  chart_data <- reactiveValues()

  # Helper function to create downloadHandler for PNG
  # Uses plotly's built-in functionality via JavaScript
  create_png_download <- function(chart_id, chart_title) {
    downloadHandler(
      filename = function() {
        paste0(gsub("[^A-Za-z0-9_-]", "_", chart_title), "_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png")
      },
      content = function(file) {
        # For Plotly charts, we'll use a workaround: save as HTML widget then screenshot
        # This requires the webshot2 package, but we'll provide a fallback message
        tryCatch({
          # Get the plotly object from the output
          # Note: This is a placeholder - actual implementation would need the plot object
          showNotification(
            "PNG download: Please use the camera icon in the chart's modebar for high-quality PNG export.",
            type = "warning",
            duration = 5
          )
          # Create empty file to avoid error
          writeLines("PNG download via modebar recommended", file)
        }, error = function(e) {
          showNotification(paste("PNG download failed:", e$message), type = "error")
          writeLines("Error", file)
        })
      }
    )
  }

  # Helper function to create downloadHandler for CSV
  create_csv_download <- function(chart_id) {
    downloadHandler(
      filename = function() {
        paste0(chart_id, "_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
      },
      content = function(file) {
        data <- chart_data[[chart_id]]
        if (is.null(data) || !is.data.frame(data)) {
          showNotification("No data available for download", type = "warning")
          writeLines("No data available", file)
        } else {
          readr::write_csv(data, file, na = "")
        }
      }
    )
  }

  # Helper to extract data from series_pack
  extract_series_data <- function(sp, chart_name) {
    if (is.null(sp)) return(NULL)
    df <- tibble::tibble(
      Year = sp$years %||% character(0),
      Actual = sp$A %||% numeric(0),
      Expected = sp$E %||% numeric(0),
      AE_Delta = sp$AE %||% numeric(0)
    )
    chart_data[[chart_name]] <- df
    df
  }

  # Helper to extract data from pivot tables
  extract_pivot_data <- function(pvt, chart_name, filters = NULL) {
    if (is.null(pvt) || !is.data.frame(pvt)) return(NULL)
    chart_data[[chart_name]] <- pvt
    pvt
  }

  # ===== Download handlers for all charts =====

  # Variance Bridge - Total
  output$dyn_ts_variance_bridge_total_download_csv <- create_csv_download("dyn_ts_variance_bridge_total")
  output$dyn_ts_variance_bridge_total_download_png <- create_png_download("dyn_ts_variance_bridge_total", "Variance Bridge Total")

  # Variance Bridge - Selection
  output$dyn_ts_variance_bridge_download_csv <- create_csv_download("dyn_ts_variance_bridge")
  output$dyn_ts_variance_bridge_download_png <- create_png_download("dyn_ts_variance_bridge", "Variance Bridge Selection")

  # Heatmap - Product x Year (Paid)
  output$dyn_heatmap_by_product_download_csv <- create_csv_download("dyn_heatmap_by_product")
  output$dyn_heatmap_by_product_download_png <- create_png_download("dyn_heatmap_by_product", "Heatmap Product Year Paid")

  # Heatmap - Product x Year (Incurred)
  output$dyn_heatmap_by_product_inc_download_csv <- create_csv_download("dyn_heatmap_by_product_inc")
  output$dyn_heatmap_by_product_inc_download_png <- create_png_download("dyn_heatmap_by_product_inc", "Heatmap Product Year Incurred")

  # Lines - Paid
  output$dyn_ts_lines_paid_download_csv <- create_csv_download("dyn_ts_lines_paid")
  output$dyn_ts_lines_paid_download_png <- create_png_download("dyn_ts_lines_paid", "Lines Paid")

  # Lines - Incurred
  output$dyn_ts_lines_incurred_download_csv <- create_csv_download("dyn_ts_lines_incurred")
  output$dyn_ts_lines_incurred_download_png <- create_png_download("dyn_ts_lines_incurred", "Lines Incurred")

  # Heatmap - Paid A-E
  output$dyn_ts_heatmap_paid_download_csv <- create_csv_download("dyn_ts_heatmap_paid")
  output$dyn_ts_heatmap_paid_download_png <- create_png_download("dyn_ts_heatmap_paid", "Heatmap Paid AE")

  # Heatmap - Incurred A-E
  output$dyn_ts_heatmap_incurred_download_csv <- create_csv_download("dyn_ts_heatmap_incurred")
  output$dyn_ts_heatmap_incurred_download_png <- create_png_download("dyn_ts_heatmap_incurred", "Heatmap Incurred AE")

  # Heatmap - Combined Paid & Incurred
  output$dyn_ts_heatmap_ae_download_csv <- create_csv_download("dyn_ts_heatmap_ae")
  output$dyn_ts_heatmap_ae_download_png <- create_png_download("dyn_ts_heatmap_ae", "Heatmap Paid Incurred AE")

  # Waterfall - Paid
  output$dyn_ts_waterfall_paid_download_csv <- create_csv_download("dyn_ts_waterfall_paid")
  output$dyn_ts_waterfall_paid_download_png <- create_png_download("dyn_ts_waterfall_paid", "Waterfall Paid")

  # Waterfall - Incurred
  output$dyn_ts_waterfall_incurred_download_csv <- create_csv_download("dyn_ts_waterfall_incurred")
  output$dyn_ts_waterfall_incurred_download_png <- create_png_download("dyn_ts_waterfall_incurred", "Waterfall Incurred")

  # Cumulative - Paid
  output$dyn_ts_cum_paid_download_csv <- create_csv_download("dyn_ts_cum_paid")
  output$dyn_ts_cum_paid_download_png <- create_png_download("dyn_ts_cum_paid", "Cumulative Paid")

  # Cumulative - Incurred
  output$dyn_ts_cum_incurred_download_csv <- create_csv_download("dyn_ts_cum_incurred")
  output$dyn_ts_cum_incurred_download_png <- create_png_download("dyn_ts_cum_incurred", "Cumulative Incurred")

  # Chart A - AvE Lines
  output$dyn_chart_A_download_csv <- create_csv_download("dyn_chart_A")
  output$dyn_chart_A_download_png <- create_png_download("dyn_chart_A", "Chart A AvE Lines")

  # Chart B - Prior Years by Segment
  output$dyn_chart_B_download_csv <- create_csv_download("dyn_chart_B")
  output$dyn_chart_B_download_png <- create_png_download("dyn_chart_B", "Chart B Prior Years")

  # Return reactive values so charts can populate them
  return(chart_data)
}
