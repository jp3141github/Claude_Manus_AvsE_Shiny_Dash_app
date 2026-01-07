# R/40_excel_writer.R — Excel export with formatting and styles

# Build summary statistics sheet
build_summary_sheet <- function(tables, uploaded_df = NULL, filters = list()) {
  summary_rows <- list()

  # ===== 1. METADATA =====
  summary_rows <- c(summary_rows, list(
    c("Section", "Value"),
    c("ANALYSIS METADATA", ""),
    c("Timestamp", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    c("Model Type", filters$model_type %||% "Not specified"),
    c("Projection Date", filters$projection_date %||% "Not specified"),
    c("Event Type", filters$event_type %||% "Non-Event"),
    c("Excluded Products", paste(filters$excluded_products %||% character(0), collapse = ", ") %||% "None"),
    c("", "")
  ))

  # ===== 2. GRAND TOTALS BY BASIS =====
  if ("Total Summary" %in% names(tables)) {
    ts <- tables[["Total Summary"]]
    if (is.data.frame(ts) && nrow(ts) > 0) {
      # Extract totals from Total Summary sheet
      total_rows <- ts %>% dplyr::filter(`A vs E` %in% c("Actual","Expected","A-E"))

      if (nrow(total_rows) > 0) {
        summary_rows <- c(summary_rows, list(
          c("GRAND TOTALS (£m)", ""),
          c("", "Paid", "Incurred")
        ))

        for (basis_label in c("Actual", "Expected", "A-E")) {
          row <- total_rows %>% dplyr::filter(`A vs E` == basis_label)
          if (nrow(row) > 0) {
            paid_val <- if ("Paid" %in% names(row)) as.character(row$Paid[1]) else "N/A"
            inc_val <- if ("Incurred" %in% names(row)) as.character(row$Incurred[1]) else "N/A"
            summary_rows <- c(summary_rows, list(c(basis_label, paid_val, inc_val)))
          }
        }
        summary_rows <- c(summary_rows, list(c("", "")))
      }
    }
  }

  # ===== 3. TOP 5 ADVERSE PRODUCTS =====
  if ("Paid A v E" %in% names(tables)) {
    pvt <- tables[["Paid A v E"]]
    if (is.data.frame(pvt) && "Product" %in% names(pvt)) {
      # Get year columns
      year_cols <- names(pvt)[grepl("^\\d{4}$", names(pvt))]

      if (length(year_cols) > 0) {
        # Calculate total A-E across all years for each product
        product_totals <- pvt %>%
          dplyr::filter(!Product %in% c("Grand Total", "Check"), !is.na(Product)) %>%
          dplyr::mutate(Total_AE = rowSums(dplyr::across(dplyr::all_of(year_cols)), na.rm = TRUE)) %>%
          dplyr::select(Product, Peril, Total_AE) %>%
          dplyr::arrange(dplyr::desc(Total_AE)) %>%
          dplyr::slice_head(n = 5)

        summary_rows <- c(summary_rows, list(
          c("TOP 5 ADVERSE PRODUCTS (Highest Positive A-E)", ""),
          c("Rank", "Product", "Peril", "Total A-E")
        ))

        for (i in seq_len(nrow(product_totals))) {
          summary_rows <- c(summary_rows, list(
            c(as.character(i),
              product_totals$Product[i],
              product_totals$Peril[i],
              sprintf("%.2f", product_totals$Total_AE[i]))
          ))
        }
        summary_rows <- c(summary_rows, list(c("", "")))
      }
    }
  }

  # ===== 4. TOP 5 FAVORABLE PRODUCTS =====
  if ("Paid A v E" %in% names(tables)) {
    pvt <- tables[["Paid A v E"]]
    if (is.data.frame(pvt) && "Product" %in% names(pvt)) {
      year_cols <- names(pvt)[grepl("^\\d{4}$", names(pvt))]

      if (length(year_cols) > 0) {
        product_totals <- pvt %>%
          dplyr::filter(!Product %in% c("Grand Total", "Check"), !is.na(Product)) %>%
          dplyr::mutate(Total_AE = rowSums(dplyr::across(dplyr::all_of(year_cols)), na.rm = TRUE)) %>%
          dplyr::select(Product, Peril, Total_AE) %>%
          dplyr::arrange(Total_AE) %>%
          dplyr::slice_head(n = 5)

        summary_rows <- c(summary_rows, list(
          c("TOP 5 FAVORABLE PRODUCTS (Highest Negative A-E)", ""),
          c("Rank", "Product", "Peril", "Total A-E")
        ))

        for (i in seq_len(nrow(product_totals))) {
          summary_rows <- c(summary_rows, list(
            c(as.character(i),
              product_totals$Product[i],
              product_totals$Peril[i],
              sprintf("%.2f", product_totals$Total_AE[i]))
          ))
        }
        summary_rows <- c(summary_rows, list(c("", "")))
      }
    }
  }

  # ===== 5. YEAR COVERAGE =====
  if (!is.null(uploaded_df) && "Accident Year" %in% names(uploaded_df)) {
    years <- suppressWarnings(as.integer(uploaded_df$`Accident Year`))
    years <- years[!is.na(years)]
    if (length(years) > 0) {
      summary_rows <- c(summary_rows, list(
        c("YEAR COVERAGE", ""),
        c("Minimum Year", as.character(min(years))),
        c("Maximum Year", as.character(max(years))),
        c("Total Years", as.character(length(unique(years)))),
        c("Total Rows", format(nrow(uploaded_df), big.mark = ",")),
        c("", "")
      ))
    }
  }

  # ===== 6. DATA QUALITY METRICS =====
  if (!is.null(uploaded_df)) {
    total_rows <- nrow(uploaded_df)
    missing_actual <- if ("Actual" %in% names(uploaded_df)) sum(is.na(uploaded_df$Actual)) else 0
    missing_expected <- if ("Expected" %in% names(uploaded_df)) sum(is.na(uploaded_df$Expected)) else 0

    summary_rows <- c(summary_rows, list(
      c("DATA QUALITY", ""),
      c("Total Rows", format(total_rows, big.mark = ",")),
      c("Missing Actual Values", sprintf("%s (%.1f%%)", format(missing_actual, big.mark = ","), missing_actual / total_rows * 100)),
      c("Missing Expected Values", sprintf("%s (%.1f%%)", format(missing_expected, big.mark = ","), missing_expected / total_rows * 100)),
      c("Completeness Score", sprintf("%.1f%%", (1 - (missing_actual + missing_expected) / (total_rows * 2)) * 100))
    ))
  }

  # Convert to data frame
  max_cols <- max(vapply(summary_rows, length, integer(1)))
  summary_df <- as.data.frame(do.call(rbind, lapply(summary_rows, function(row) {
    c(row, rep("", max_cols - length(row)))
  })), stringsAsFactors = FALSE)

  # Set column names
  names(summary_df) <- paste0("Col", seq_len(ncol(summary_df)))
  names(summary_df)[1:2] <- c("Metric", "Value")

  summary_df
}

write_excel <- function(tables, output_path, uploaded_df = NULL, filters = list()) {
  # Add summary sheet at the beginning
  summary_sheet <- build_summary_sheet(tables, uploaded_df, filters)
  tables <- c(list("Summary" = summary_sheet), tables)


  # Drop any non-data-frame entries (defensive)
  tables <- Filter(function(x) inherits(x, "data.frame"), tables)
  wb <- openxlsx::createWorkbook()
  
  # styles
  s_txtL      <- createStyle(halign="left", indent=1)
  s_txtB      <- createStyle(halign="left", indent=1, textDecoration="bold")
  s_txtGrey   <- createStyle(halign="left", indent=1, fgFill="#EEEEEE")
  s_num1      <- createStyle(numFmt="#,##0.0;[Red]-#,##0.0", halign="right", indent=1)
  s_num2      <- createStyle(numFmt="#,##0.00;[Red]-#,##0.00", halign="right", indent=1)
  s_pct1      <- createStyle(numFmt="0.0%;[Red]-0.0%", halign="right", indent=1)
  s_hdrAB     <- createStyle(textDecoration="bold", border="TopBottomLeftRight", halign="left", indent=1)
  s_hdrThick  <- createStyle(textDecoration="bold", wrapText=TRUE, border="TopBottomLeftRight", halign="center", valign="center")
  s_hdrNA     <- createStyle(fontColour="#FFFFFF")
  s_y_txt     <- createStyle(fgFill="#FFF59D", halign="left", indent=1, border="TopBottom")
  s_y_num2    <- createStyle(fgFill="#FFF59D", numFmt="#,##0.00;[Red]-#,##0.00", halign="right", indent=1, border="TopBottom")
  s_y_pct     <- createStyle(fgFill="#FFF59D", numFmt="0.0%;[Red]-0.0%", halign="right", indent=1, border="TopBottom")
  s_grey_num2 <- createStyle(fgFill="#EEEEEE", numFmt="#,##0.00;[Red]-#,##0.00", halign="right", indent=1)
  s_grey_txt  <- createStyle(fgFill="#EEEEEE", halign="left", indent=1)
  s_gt_txtL   <- createStyle(textDecoration="bold", border=c("top","bottom","left"),   halign="left",  indent=1, borderStyle="thick")
  s_gt_txt    <- createStyle(textDecoration="bold", border=c("top","bottom"),          halign="left",  indent=1, borderStyle="thick")
  s_gt_txtR   <- createStyle(textDecoration="bold", border=c("top","bottom","right"),  halign="left",  indent=1, borderStyle="thick")
  s_gt_num1L  <- createStyle(textDecoration="bold", numFmt="#,##0.0;[Red]-#,##0.0", halign="right", indent=1, border=c("top","bottom","left"),  borderStyle="thick")
  s_gt_num1   <- createStyle(textDecoration="bold", numFmt="#,##0.0;[Red]-#,##0.0", halign="right", indent=1, border=c("top","bottom"),         borderStyle="thick")
  s_gt_num1R  <- createStyle(textDecoration="bold", numFmt="#,##0.0;[Red]-#,##0.0", halign="right", indent=1, border=c("top","bottom","right"), borderStyle="thick")
  s_gt_pctL   <- createStyle(textDecoration="bold", numFmt="0.0%;[Red]-0.0%", halign="right", indent=1, border=c("top","bottom","left"),  borderStyle="thick")
  s_gt_pct    <- createStyle(textDecoration="bold", numFmt="0.0%;[Red]-0.0%", halign="right", indent=1, border=c("top","bottom"),         borderStyle="thick")
  s_gt_pctR   <- createStyle(textDecoration="bold", numFmt="0.0%;[Red]-0.0%", halign="right", indent=1, border=c("top","bottom","right"), borderStyle="thick")
  s_bg_green  <- createStyle(fgFill = "#C8E6C9")
  s_bg_orange <- createStyle(fgFill = "#FFE0B2")
  
  thin_outline <- function(ws, rows, cols) { addStyle(wb, ws, createStyle(border="TopBottomLeftRight"), rows=rows, cols=cols, gridExpand=TRUE, stack=TRUE, borderStyle="thin") }
  auto_widths <- function(ws, df, decimals=1) {
    for (j in seq_along(df)) {
      col <- df[[j]]; is_num <- is.numeric(col)
      width <- max(8, min(55, nchar(names(df)[j]) + 2,
                          if (is_num) max(nchar(formatC(head(col, 1000), format="f", digits=decimals)), na.rm=TRUE)+2
                          else max(nchar(as.character(head(col, 1000))), na.rm=TRUE)+2))
      setColWidths(wb, ws, j, width)
    }
  }
  
  for (nm in names(tables)) addWorksheet(wb, substr(nm, 1, 31))
  for (nm in names(tables)) {
    ws <- substr(nm, 1, 31)
    df <- tables[[nm]]
    
    # RAW precise numerics
    if (is_raw_sheet_name(ws) && nrow(df)) {
      fix_num <- function(x) {
        if (is.numeric(x)) return(x)
        z <- as.character(x)
        z <- gsub("[£,]", "", z)                 # strip £ and thousand separators
        z <- gsub("\\(([^)]*)\\)", "-\\1", z)    # (123) -> -123
        z <- chartr("\u2212", "-", z)            # unicode minus -> ascii
        z <- trimws(z)
        suppressWarnings(as.numeric(z))
      }
      if ("Accident Year"   %in% names(df)) df[["Accident Year"]]   <- round(fix_num(df[["Accident Year"]]), 0)
      if ("Accident Period" %in% names(df)) df[["Accident Period"]] <- fix_num(df[["Accident Period"]])
      for (nmcol in c("Actual","Expected","A - E")) if (nmcol %in% names(df)) df[[nmcol]] <- fix_num(df[[nmcol]])
    }
    
    # clean non-finite in all sheets
    df[] <- lapply(df, function(col) {
      suppressWarnings({
        as_num <- suppressWarnings(as.numeric(col))
        bad <- !is.na(as_num) & !is.finite(as_num)
        if (any(bad)) col[bad] <- NA
      })
      col
    })
    
    writeData(wb, ws, df, withFilter = FALSE)
    
    # headers
    for (j in seq_along(df)) {
      hdr_style <- if (startsWith(names(df)[j], "nil")) s_hdrNA else if (j <= 2) s_hdrAB else s_hdrThick
      addStyle(wb, ws, hdr_style, rows = 1, cols = j, gridExpand = TRUE)
    }
    setRowHeights(wb, ws, rows = 1, heights = 30)
    
    # default numeric/text formats
    num_style <- if (ws == "Total Summary") s_num2 else s_num1
    raw_skip <- character(0)
    if (is_raw_sheet_name(ws)) raw_skip <- intersect(c("Accident Year","Accident Period","Actual","Expected","A - E"), names(df))
    
    for (j in seq_along(df)) {
      colname <- names(df)[j]
      if (is_raw_sheet_name(ws) && colname %in% raw_skip) next
      addStyle(
        wb, ws,
        if (is.numeric(df[[j]])) num_style else s_txtL,
        rows = 2:(nrow(df) + 1), cols = j, gridExpand = TRUE
      )
    }
    
    # RAW precise number formats (no stack)
    if (is_raw_sheet_name(ws) && nrow(df)) {
      s_year0   <- createStyle(numFmt = "0",    halign = "right", indent = 1)
      s_period1 <- createStyle(numFmt = "0.0",  halign = "right", indent = 1)
      s_num0    <- createStyle(numFmt = "#,##0;[Red]-#,##0", halign = "right", indent = 1)
      if ("Accident Year" %in% names(df)) {
        j <- which(names(df) == "Accident Year")
        addStyle(wb, ws, s_year0, rows = 2:(nrow(df) + 1), cols = j, gridExpand = TRUE, stack = FALSE)
      }
      if ("Accident Period" %in% names(df)) {
        j <- which(names(df) == "Accident Period")
        addStyle(wb, ws, s_period1, rows = 2:(nrow(df) + 1), cols = j, gridExpand = TRUE, stack = FALSE)
      }
      for (nmcol in c("Actual","Expected","A - E")) if (nmcol %in% names(df)) {
        j <- which(names(df) == nmcol)
        addStyle(wb, ws, s_num0, rows = 2:(nrow(df) + 1), cols = j, gridExpand = TRUE, stack = FALSE)
      }
    }
    
    # Total Summary banding
    if (ws == "Total Summary" && nrow(df)) {
      ridx <- function(lbl) which(df$`A vs E` == lbl) + 1
      r_ae  <- ridx("A-E")
      r_pct <- ridx("%")
      r_chk <- ridx("Check")
      if (length(r_ae))  { addStyle(wb, ws, s_y_num2,  rows = rep(r_ae,  each = ncol(df) - 2), cols = 3:ncol(df), gridExpand = TRUE, stack = TRUE)
        addStyle(wb, ws, s_y_txt,   rows = r_ae,  cols = 1:2, gridExpand = TRUE, stack = TRUE) }
      if (length(r_pct)) { addStyle(wb, ws, s_y_pct,   rows = rep(r_pct, each = ncol(df) - 2), cols = 3:ncol(df), gridExpand = TRUE, stack = TRUE)
        addStyle(wb, ws, s_y_txt,   rows = r_pct, cols = 1:2, gridExpand = TRUE, stack = TRUE) }
      if (length(r_chk)) { addStyle(wb, ws, s_grey_num2, rows = rep(r_chk, each = ncol(df) - 2), cols = 3:ncol(df), gridExpand = TRUE, stack = TRUE)
        addStyle(wb, ws, s_grey_txt,  rows = r_chk, cols = 1:2, gridExpand = TRUE, stack = TRUE) }
      setColWidths(wb, ws, 1, 16); setColWidths(wb, ws, 2, 14)
    }
    
    # Class sheets outlines & GT
    is_class_sheet <- ws %in% c("Class Summary", "Class Peril Summary", "Class Summary pct", "Class Peril Summary pct")
    if (is_class_sheet && nrow(df)) {
      last_outline_col <- min(11, ncol(df))
      thin_outline(ws, rows = 2:(nrow(df) + 1), cols = 1:last_outline_col)
      val_cols <- which(!(startsWith(names(df), "nil")) & seq_along(df) >= 3)
      addStyle(wb, ws, if (endsWith(ws, "pct")) s_pct1 else s_num1,
               rows = 2:(nrow(df) + 1), cols = val_cols, gridExpand = TRUE, stack = TRUE)
      ends_pct <- endsWith(ws, "pct")
      key_col  <- if ("Class/Peril" %in% names(df)) "Class/Peril" else names(df)[2]
      key_norm <- toupper(trimws(as.character(df[[key_col]])))
      rgt <- which(key_norm == "GRAND TOTAL") + 1
      if (length(rgt)) {
        addStyle(wb, ws, s_gt_txtL, rows = rgt, cols = 1, stack = TRUE)
        addStyle(wb, ws, if (ends_pct) s_gt_pct else s_gt_num1,
                 rows = rgt, cols = val_cols, gridExpand = TRUE, stack = TRUE)
        addStyle(wb, ws, s_gt_txtR, rows = rgt, cols = last_outline_col, stack = TRUE)
      }
      if ("Peril" %in% names(df)) {
        peril_norm <- toupper(trimws(as.character(df$Peril)))
        rtot <- which(peril_norm == "TOTAL") + 1
        if (length(rtot)) {
          addStyle(wb, ws, s_txtGrey, rows = rtot, cols = 1:2, gridExpand = TRUE, stack = TRUE)
          addStyle(wb, ws, if (ends_pct) s_pct1 else s_num1,
                   rows = rep(rtot, each = length(val_cols)),
                   cols = val_cols, gridExpand = TRUE, stack = TRUE)
        }
      }
      rcheck <- which(key_norm == "CHECK") + 1
      if (length(rcheck)) {
        addStyle(wb, ws, s_txtGrey, rows = rcheck, cols = 1:2, gridExpand = TRUE, stack = TRUE)
        addStyle(wb, ws, if (ends_pct) s_pct1 else s_grey_num2,
                 rows = rep(rcheck, each = length(val_cols)),
                 cols = val_cols, gridExpand = TRUE, stack = TRUE)
      }
    }
    
    # Paid/Inc sheets outlines (+ AvE conditional fills)
    if (ws %in% c(
      SHEET_NAMES$paid_ave, SHEET_NAMES$incurred_ave,
      "Paid A v E – NIG","Paid A v E – Non NIG",
      "Incurred A v E – NIG","Incurred A v E – Non NIG"
    )) {
      is_year_name <- function(x) { y <- suppressWarnings(as.integer(x)); is.finite(y) & y >= 1900 & y <= 2100 }
      year_cols <- which(vapply(names(df), is_year_name, logical(1)))
      if (length(year_cols)) {
        start_col <- min(year_cols)
        end_col   <- ncol(df)
        start_row <- 2
        end_row   <- nrow(df) + 1
        
        # Use 'expression' rules anchored to the top-left of the region
        anchor_col <- openxlsx::int2col(start_col)
        anchor_ref <- paste0(anchor_col, start_row)  # e.g., "D2"
        
        openxlsx::conditionalFormatting(
          wb, ws,
          cols = start_col:end_col, rows = start_row:end_row,
          type = "expression", rule = paste0(anchor_ref, ">2.5"),
          style = s_bg_orange
        )
        
        openxlsx::conditionalFormatting(
          wb, ws,
          cols = start_col:end_col, rows = start_row:end_row,
          type = "expression", rule = paste0(anchor_ref, "<-2.5"),
          style = s_bg_green
        )
      }
    }
    
    # Auto widths
    auto_widths(ws, df, decimals = if (ws == "Total Summary") 2 else 1)
  } # end for(nm in names(tables))
  
  saveWorkbook(wb, output_path, overwrite = TRUE)
}
