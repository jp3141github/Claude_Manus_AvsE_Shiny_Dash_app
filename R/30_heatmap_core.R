# R/30_heatmap_core.R — Heatmap building functions (Product × Year)

# --- CHM-FIX 1: helpers (put near your other utilities) -----------------------

# full sequence of years to display
.full_years <- function(df, year_col = "accidentyear", min_year = NULL, max_year = NULL) {
  y <- suppressWarnings(as.integer(as.character(df[[year_col]])))
  y <- y[is.finite(y)]
  if (!length(y)) return(integer(0))
  y_min <- if (is.null(min_year)) min(y) else min_year
  y_max <- if (is.null(max_year)) max(y) else max_year
  seq.int(y_min, y_max)
}

# compact tick labels
.year_labels <- function(years) fmt_year_labels(years)

# CHM-FIX 2: summarize to unique Product×Year (and count contributing rows)
#   agg_fn can be sum/mean/etc. (a function taking numeric vector -> scalar)
.summarise_prod_year <- function(df,
                                 product_col = "Product",
                                 year_col    = "accidentyear",
                                 value_col   = "AE_value",
                                 agg_fn      = base::sum,
                                 na_rm       = TRUE,
                                 drop_product_zero = TRUE,
                                 drop_segment_na   = TRUE,
                                 segment_col = "SegmentGroup") {
  stopifnot(all(c(product_col, year_col, value_col) %in% names(df)))
  
  # drop noisy rows
  if (drop_product_zero) {
    df <- df[!(df[[product_col]] %in% c(0, "0")), , drop = FALSE]
  }
  if (drop_segment_na && segment_col %in% names(df)) {
    df <- df[!is.na(df[[segment_col]]), , drop = FALSE]
  }
  
  # standardise year to integer
  df[[year_col]] <- suppressWarnings(as.integer(as.character(df[[year_col]])))
  
  # ensure numeric value column
  df[[value_col]] <- suppressWarnings(as.numeric(df[[value_col]]))
  
  # real aggregation
  agg <- df |>
    dplyr::group_by(.data[[product_col]], .data[[year_col]]) |>
    dplyr::summarise(
      value = agg_fn(.data[[value_col]], na.rm = na_rm),
      n     = dplyr::n(), .groups = "drop"
    )
  
  names(agg)[1:2] <- c(product_col, year_col)
  agg
}

# CHM-FIX 3: build heatmap (pre-aggregates, pads grid, strict hover)
build_heatmap_px <- function(df,
                             product_col   = "Product",
                             year_col      = "accidentyear",
                             value_col     = "AE_value",
                             title         = "Heatmap – Product × Year",
                             palette       = "RdBu",
                             zmid          = 0,
                             zmin          = NA_real_,   # auto symmetric
                             zmax          = NA_real_,
                             min_year      = NULL, max_year = NULL,
                             product_order = NULL,
                             agg_fn        = base::sum,  # change to mean if needed
                             na_rm         = TRUE) {
  
  suppressPackageStartupMessages({
    library(dplyr); library(tidyr); library(plotly); library(RColorBrewer)
  })
  
  # allow callers to pass AE_value under different names; copy to AE_value if needed
  if (!("AE_value" %in% names(df))) {
    df$AE_value <- df[[value_col]]
    value_col <- "AE_value"
  }
  
  # strip the literal word "combo" from any axis label columns that might show up
  for (nm in intersect(c(product_col, year_col, "AxisLabel"), names(df))) {
    if (is.character(df[[nm]]) || is.factor(df[[nm]])) {
      df[[nm]] <- gsub("\\bcombo\\b", "", as.character(df[[nm]]), ignore.case = TRUE)
      df[[nm]] <- trimws(gsub("\\s+", " ", df[[nm]]))
    }
  }
  
  # 1) summarise to unique Product×Year + count
  agg <- .summarise_prod_year(
    df, product_col = product_col, year_col = year_col, value_col = value_col,
    agg_fn = agg_fn, na_rm = na_rm
  )
  
  # 2) establish full frame (years + products)
  yrs <- .full_years(agg, year_col = year_col, min_year = min_year, max_year = max_year)
  if (!length(yrs)) {
    return(plotly::plot_ly() |> plotly::layout(title = list(text = paste0(title, " (no data)"))))
  }
  prods <- if (is.null(product_order)) sort(unique(agg[[product_col]])) else {
    c(intersect(product_order, unique(agg[[product_col]])),
      setdiff(sort(unique(agg[[product_col]])), product_order))
  }
  
  # 3) pad to full Product×Year frame
  pad <- tidyr::complete(
    agg,
    !!rlang::sym(product_col) := prods,
    !!rlang::sym(year_col)    := yrs
  ) |>
    dplyr::mutate(
      !!rlang::sym(product_col) := factor(.data[[product_col]], levels = prods),
      !!rlang::sym(year_col)    := factor(.data[[year_col]],    levels = yrs)
    )
  
  # build hover text before widening
  pad$text <- ifelse(
    is.na(pad$value),
    sprintf(
      "Product: %s<br>Year: %s<br>Value: NA<br>n: %d",
      as.character(pad[[product_col]]),
      as.character(pad[[year_col]]),
      ifelse(is.na(pad$n), 0L, as.integer(pad$n))
    ),
    sprintf(
      "Product: %s<br>Year: %s<br>Value: %s<br>n: %d",
      as.character(pad[[product_col]]),
      as.character(pad[[year_col]]),
      formatC(pad$value, format = "f", digits = 2),
      ifelse(is.na(pad$n), 1L, as.integer(pad$n))
    )
  )
  
  # 4) wide matrices for z (value) and text (hover)
  wide_val <- tidyr::pivot_wider(
    pad, names_from = !!rlang::sym(year_col), values_from = "value"
  ) |>
    dplyr::arrange(!!rlang::sym(product_col))
  
  wide_txt <- tidyr::pivot_wider(
    pad, names_from = !!rlang::sym(year_col), values_from = "text"
  ) |>
    dplyr::arrange(!!rlang::sym(product_col))
  
  # derive axes directly from the wide frames to guarantee shape match
  prod_levels        <- as.character(wide_val[[product_col]])
  year_levels_char   <- setdiff(names(wide_val), product_col)   # the year columns as strings
  
  z   <- as.matrix(wide_val[, year_levels_char, drop = FALSE])
  txt <- as.matrix(wide_txt[, year_levels_char, drop = FALSE])
  
  # ticks (use the same order as the matrix columns)
  tickvals <- year_levels_char
  ticktext <- .year_labels(as.integer(year_levels_char))
  
  # derive color scale limits (symmetric unless user provided)
  z_vals <- suppressWarnings(as.numeric(z))
  if (all(is.na(z_vals))) {
    zmin_eff <- if (is.finite(zmin)) zmin else -1
    zmax_eff <- if (is.finite(zmax)) zmax else 1
  } else {
    if (is.finite(zmin) && is.finite(zmax)) {
      zmin_eff <- zmin; zmax_eff <- zmax
    } else {
      mm <- max(abs(z_vals), na.rm = TRUE)
      zmin_eff <- -mm; zmax_eff <- mm
    }
  }
  
  plotly::plot_ly(
    type = "heatmap",
    x = tickvals, y = prod_levels, z = z,
    text = txt, hoverinfo = "text",
    hovertemplate = "%{text}<extra></extra>",
    colorscale = palette,         # e.g., "RdBu"
    zmin = zmin_eff, zmax = zmax_eff, zmid = zmid,
    showscale = TRUE
  ) |>
    
    plotly::layout(
      title  = list(text = title),
      margin = list(l = 80, r = 40, t = 60, b = 70),
      xaxis  = list(
        type = "category",
        categoryorder = "array", categoryarray = tickvals,
        tickmode = "array", tickvals = tickvals, ticktext = ticktext,
        automargin = TRUE, title = list(text = "Year")
      ),
      yaxis  = list(
        type = "category",
        categoryorder = "array", categoryarray = prod_levels,
        automargin = TRUE, title = list(text = "Product"),
        autorange = "reversed"  # <<< ensures A at top, Z at bottom
      )
    )
}
