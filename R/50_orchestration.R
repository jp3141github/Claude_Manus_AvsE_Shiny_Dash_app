# R/50_orchestration.R — Main orchestration function (build_all_tables)

build_all_tables <- function(raw_df,
                             model_type,
                             projection_date,
                             event_type,
                             excluded_products = character(0)) {
  
  # header renamers (display-only, keep once)
  rename_ave_headers <- function(df) {
    nm <- names(df)
    nm <- sub("^PY Paid$",        "PY Paid\nA vs E",        nm)
    nm <- sub("^PY Incurred$",    "PY Incurred\nA vs E",    nm)
    nm <- sub("^CY Paid$",        "CY Paid\nA vs E",        nm)
    nm <- sub("^CY Incurred$",    "CY Incurred\nA vs E",    nm)
    nm <- sub("^Total Paid$",     "Total Paid\nA vs E",     nm)
    nm <- sub("^Total Incurred$", "Total Incurred\nA vs E", nm)
    names(df) <- nm; df
  }
  rename_ave_headers_pct <- function(df) {
    nm <- names(df)
    nm <- sub("^PY Paid$",        "PY Paid\nA vs E %",        nm)
    nm <- sub("^PY Incurred$",    "PY Incurred\nA vs E %",    nm)
    nm <- sub("^CY Paid$",        "CY Paid\nA vs E %",        nm)
    nm <- sub("^CY Incurred$",    "CY Incurred\nA vs E %",    nm)
    nm <- sub("^Total Paid$",     "Total Paid\nA vs E %",     nm)
    nm <- sub("^Total Incurred$", "Total Incurred\nA vs E %", nm)
    names(df) <- nm; df
  }
  
  df  <- ensure_columns(raw_df)
  df  <- coerce_types(df)
  
  # Global exclusions first (affects RAW + all outputs)
  if (length(excluded_products)) df <- df %>% dplyr::filter(!(Product %in% excluded_products))
  
  df_f <- apply_filters(df, model_type = model_type, projection_date = projection_date, event_type = event_type) %>%
    dplyr::filter(!is.na(Measure) & Measure %in% c("Paid","Incurred"))
  if (!nrow(df_f)) showNotification("No Paid/Incurred rows remain after filtering/derivation — outputs will be zero.", type = "error", duration = 8)
  .debug_headcounts(df_f)
  
  years_present <- sort(unique(suppressWarnings(as.integer(na.omit(df_f[["Accident Year"]])))))
  # preferred reporting window
  years_pref <- years_present[years_present >= 2010 & years_present <= 2025]
  years <- if (length(years_pref)) years_pref else years_present
  # if STILL empty, bail out explicitly so you see a clear warning rather than a blank sheet
  if (!length(years)) {
    showNotification("No valid Accident Years after filters — Total Summary would be empty.", type = "error", duration = 8)
    years <- integer(0)
  }
  
  # ---- Column-name de-duplicator (make names unique, keep all columns) ----
  .dedupe_names <- function(df) {
    if (is.null(df) || !ncol(df)) return(df)
    names(df) <- make.unique(names(df), sep = " ")
    df
  }
  
  paid_ave      <- .dedupe_names(scale_millions(build_paid_ave(df_f, years)))
  incurred_ave  <- .dedupe_names(scale_millions(build_incurred_ave(df_f, years)))
  paid_a        <- .dedupe_names(scale_millions(build_paid_a(df_f, years)))
  paid_e        <- .dedupe_names(scale_millions(build_paid_e(df_f, years)))
  incurred_a    <- .dedupe_names(scale_millions(build_incurred_a(df_f, years)))
  incurred_e    <- .dedupe_names(scale_millions(build_incurred_e(df_f, years)))
  
  total_summary <- .dedupe_names(build_total_summary(df_f, years))
  class_summary <- .dedupe_names(build_class_summary_with_segment(df_f))
  class_peril_summary       <- .dedupe_names(build_class_peril_summary_with_segment(df_f))
  class_summary_pct         <- .dedupe_names(build_class_summary_pct_with_segment(df_f))
  class_peril_summary_pct   <- .dedupe_names(build_class_peril_summary_pct_with_segment(df_f))
  
  # Segment-group views for AvE pivots
  df_nig <- df_f %>% dplyr::filter(Segment == "NIG")
  df_non <- df_f %>% dplyr::filter(Segment != "NIG" | is.na(Segment))
  
  paid_ave_nig       <- scale_millions(build_paid_ave(df_nig, years))
  paid_ave_non_nig   <- scale_millions(build_paid_ave(df_non, years))
  incurred_ave_nig   <- scale_millions(build_incurred_ave(df_nig, years))
  incurred_ave_non_nig <- scale_millions(build_incurred_ave(df_non, years))
  
  # display header tweaks
  class_summary             <- rename_ave_headers(class_summary)
  class_peril_summary       <- rename_ave_headers(class_peril_summary)
  class_summary_pct         <- rename_ave_headers_pct(class_summary_pct)
  class_peril_summary_pct   <- rename_ave_headers_pct(class_peril_summary_pct)
  
  # guard for stray blank Product column in pct table
  if ("Product" %in% names(class_peril_summary_pct) &&
      all(is.na(class_peril_summary_pct$Product) | class_peril_summary_pct$Product == "")) {
    class_peril_summary_pct$Product <- NULL
  }
  
  paid_ave        <- paid_ave        %>% dplyr::mutate(`Segment (Group)`="All")     %>% dplyr::relocate(`Segment (Group)`, .after=Peril)
  incurred_ave    <- incurred_ave    %>% dplyr::mutate(`Segment (Group)`="All")     %>% dplyr::relocate(`Segment (Group)`, .after=Peril)
  paid_ave_nig    <- paid_ave_nig    %>% dplyr::mutate(`Segment (Group)`="NIG")     %>% dplyr::relocate(`Segment (Group)`, .after=Peril)
  paid_ave_non_nig<- paid_ave_non_nig%>% dplyr::mutate(`Segment (Group)`="Non NIG") %>% dplyr::relocate(`Segment (Group)`, .after=Peril)
  incurred_ave_nig<- incurred_ave_nig%>% dplyr::mutate(`Segment (Group)`="NIG")     %>% dplyr::relocate(`Segment (Group)`, .after=Peril)
  incurred_ave_non_nig <- incurred_ave_non_nig %>% dplyr::mutate(`Segment (Group)`="Non NIG") %>% dplyr::relocate(`Segment (Group)`, .after=Peril)
  
  # RAW output after exclusions/filters
  raw_out <- df[, c(EXPECTED_COLUMNS, "A - E"), drop = FALSE]
  if ("ProjectionDate" %in% names(raw_out)) {
    pd <- parse_projection_date_dateonly(raw_out[["ProjectionDate"]])
    raw_out[["ProjectionDate"]] <- ifelse(!is.na(pd), format(pd, "%d-%m-%Y"), NA_character_)
  }
  
  class_summary_pct       <- .ids_text_guard(class_summary_pct)
  class_peril_summary_pct <- .ids_text_guard(class_peril_summary_pct)
  
  out <- list()
  out[[SHEET_NAMES$total_summary]]       <- total_summary
  out[[SHEET_NAMES$class_summary]]       <- class_summary
  out[["Class Summary pct"]]             <- class_summary_pct
  out[[SHEET_NAMES$class_peril_summary]] <- class_peril_summary
  out[["Class Peril Summary pct"]]       <- class_peril_summary_pct
  out[[SHEET_NAMES$paid_ave]]            <- paid_ave
  out[[SHEET_NAMES$incurred_ave]]        <- incurred_ave
  out[[SHEET_NAMES$paid_a]]              <- paid_a
  out[[SHEET_NAMES$paid_e]]              <- paid_e
  out[[SHEET_NAMES$incurred_a]]          <- incurred_a
  out[[SHEET_NAMES$incurred_e]]          <- incurred_e
  
  # --- E2: add NIG / Non-NIG versions ---
  out[["Paid A v E – NIG"]]         <- paid_ave_nig
  out[["Paid A v E – Non NIG"]]     <- paid_ave_non_nig
  out[["Incurred A v E – NIG"]]     <- incurred_ave_nig
  out[["Incurred A v E – Non NIG"]] <- incurred_ave_non_nig
  
  out[[SHEET_NAMES$raw]] <- raw_out
  
  # final safety pass over all tables
  for (nm in names(out)) {
    if (inherits(out[[nm]], "data.frame")) out[[nm]] <- .dedupe_names(out[[nm]])
  }
  
  out
}
