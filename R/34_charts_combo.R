# R/34_charts_combo.R — Combined chart functions (selection-aware helpers)

# ---------- Selection-aware chart helpers ----------
get_table_by <- function(res,
                         basis = c("Paid","Incurred"),
                         kind  = c("Actual","Expected","AE"),
                         seg_group = c("All","NIG","Non NIG")) {
  basis    <- match.arg(basis)
  kind     <- match.arg(kind)
  seg_group<- match.arg(seg_group)
  
  # choose sheet base by basis/kind
  nm_core <- switch(paste(basis, kind),
                    "Paid Actual"       = "Paid A",
                    "Paid Expected"     = "Paid E",
                    "Paid AE"           = SHEET_NAMES$paid_ave,
                    "Incurred Actual"   = "Incurred A",
                    "Incurred Expected" = "Incurred E",
                    "Incurred AE"       = SHEET_NAMES$incurred_ave
  )
  
  # switch to NIG/Non NIG AvE sheets for AE when requested
  if (kind == "AE" && seg_group != "All") {
    nm_core <- switch(paste(basis, seg_group),
                      "Paid NIG"       = "Paid A v E – NIG",
                      "Paid Non NIG"   = "Paid A v E – Non NIG",
                      "Incurred NIG"   = "Incurred A v E – NIG",
                      "Incurred Non NIG" = "Incurred A v E – Non NIG",
                      nm_core
    )
  }
  
  res[[nm_core]]
}

pp_filter <- function(df, prod_sel, peril_sel) {
  if (is.null(df) || !nrow(df)) return(df)
  df <- df %>% mutate(Product = as.character(Product), Peril = as.character(Peril))
  if (!identical(prod_sel, "ALL")) df <- df %>% filter(Product == prod_sel)
  if (!identical(peril_sel, "ALL")) {
    df <- df %>% filter(Peril == peril_sel)
  } else {
    # sum across perils but avoid the roll-up row
    df <- df %>% filter(toupper(trimws(Peril)) != "TOTAL")
  }
  df
}

align_series <- function(s_years, s_vals, years) {
  if (!length(years)) return(numeric())
  if (!length(s_years)) return(rep(NA_real_, length(years)))
  m   <- match(years, s_years)
  out <- rep(NA_real_, length(years))
  ok  <- !is.na(m)
  out[ok] <- s_vals[m[ok]]
  out
}

series_pp <- function(res, prod_sel, peril_sel,
                      basis = c("Paid","Incurred"),
                      kind  = c("Actual","Expected","AE"),
                      seg_group = c("All","NIG","Non NIG")) {
  basis     <- match.arg(basis)
  kind      <- match.arg(kind)
  seg_group <- match.arg(seg_group)
  tab <- get_table_by(res, basis = basis, kind = kind, seg_group = seg_group)
  if (is.null(tab) || !nrow(tab)) return(list(years = integer(), values = numeric()))
  years <- ts_year_cols(tab)
  if (!length(years)) return(list(years = integer(), values = numeric()))
  dsel <- pp_filter(tab, prod_sel, peril_sel)
  vals <- if (nrow(dsel)) colSums(dsel[, as.character(years), drop = FALSE], na.rm = TRUE)
  else rep(NA_real_, length(years))
  list(years = years, values = as.numeric(vals))
}

series_pack <- function(res, prod_sel, peril_sel, basis = c("Paid","Incurred"),
                        seg_group = c("All","NIG","Non NIG")) {
  basis     <- match.arg(basis)
  seg_group <- match.arg(seg_group)
  sA <- series_pp(res, prod_sel, peril_sel, basis = basis, kind = "Actual",   seg_group = seg_group)
  sE <- series_pp(res, prod_sel, peril_sel, basis = basis, kind = "Expected", seg_group = seg_group)
  years <- sort(unique(c(sA$years, sE$years)))
  A  <- align_series(sA$years, sA$values, years)
  E  <- align_series(sE$years, sE$values, years)
  AE <- A - E
  list(years = years, Actual = A, Expected = E, AE = AE)
}
