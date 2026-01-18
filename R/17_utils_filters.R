# R/17_utils_filters.R — selection normalisation + filters + debug (tolerant & NA-safe)

# Local %||% (in case not already sourced)
`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0) return(b)
  if (is.atomic(a) && length(a) == 1) {
    if (is.character(a) && !nzchar(a)) return(b)
    if (is.logical(a)   && is.na(a))   return(b)
  }
  a
}

# Normalise to lower, strip non [a-z0-9]
norm_key <- function(x) gsub("[^a-z0-9]", "", tolower(trimws(as.character(x))))

# Event mapper -> "event" / "nonevent"
map_event <- function(x) {
  s <- norm_key(x)
  dplyr::case_when(
    startsWith(s, "non")   ~ "nonevent",
    startsWith(s, "event") ~ "event",
    TRUE                   ~ s
  )
}

# Utility: first present column name from a set of candidates (or NULL if none)
first_present_col <- function(df, candidates) {
  cand <- intersect(candidates, names(df))
  if (length(cand)) cand[[1]] else NULL
}

apply_filters <- function(df, model_type, projection_date, event_type) {
  if (is.null(df) || nrow(df) == 0) return(df)
  
  keep <- rep(TRUE, nrow(df))
  
  # Column name candidates (tolerate small schema drift)
  mt_col_nm   <- first_present_col(df, c("Model Type","model_type","ModelType"))
  pd_col_nm   <- first_present_col(df, c("ProjectionDate","projectiondate","Projection Date"))
  ev_col_nm   <- first_present_col(df, c("Event / Non-Event","Event/Non-Event","EventNonEvent","event_type"))
  
  # ---- Model Type -----------------------------------------------------------
  if (!is.null(model_type) && nzchar(model_type) && !is.null(mt_col_nm)) {
    mt_col <- tolower(trimws(as.character(df[[mt_col_nm]])))
    mt_val <- tolower(trimws(model_type))
    has_any <- any(mt_col == mt_val, na.rm = TRUE)
    if (isTRUE(has_any)) {
      keep <- keep & (mt_col == mt_val)
    } else {
      showNotification(glue::glue("Skipping Model Type filter (no rows match '{model_type}')."),
                       type = "warning", duration = 5)
    }
  }
  
  # ---- Projection Date ------------------------------------------------------
  if (!is.null(projection_date) && !is.na(projection_date) && !is.null(pd_col_nm)) {
    proj_col <- parse_projection_date_dateonly(df[[pd_col_nm]])
    tgt <- as.Date(projection_date)
    has_any <- any(!is.na(proj_col) & as.Date(proj_col) == tgt)
    if (isTRUE(has_any)) {
      keep <- keep & (as.Date(proj_col) == tgt)
    } else {
      showNotification(glue::glue("Skipping Projection Date filter (no rows match {format(tgt,'%Y/%m/%d')})."),
                       type = "warning", duration = 5)
    }
  }
  
  # ---- Event / Non-Event ----------------------------------------------------
  if (!is.null(event_type) && nzchar(event_type) && !is.null(ev_col_nm)) {
    ev_col <- map_event(df[[ev_col_nm]])
    ev_in  <- map_event(event_type)[1]
    present <- any(ev_col %in% c("event","nonevent"), na.rm = TRUE)
    has_any <- present && any(ev_col == ev_in, na.rm = TRUE)
    if (isTRUE(has_any)) {
      keep <- keep & (ev_col == ev_in)
    } else {
      showNotification(glue::glue("Skipping Event filter (no rows match '{event_type}')."),
                       type = "warning", duration = 5)
    }
  }
  
  out <- df[keep, , drop = FALSE]
  
  # ---- Post-filter sanity notes (vector-safe) --------------------------------
  has_paid_incd <- ("Measure" %in% names(out)) && any(out$Measure %in% c("Paid","Incurred"), na.rm = TRUE)
  
  if (!nrow(out) || !has_paid_incd) {
    showNotification("No Paid/Incurred rows after filters.", type = "error", duration = 8)
  }
  
  out
}

.debug_headcounts <- function(df) {
  cat("\n[DEBUG] Rows post-filter:", if (!is.null(df)) nrow(df) else 0, "\n")
  if (is.null(df) || !nrow(df)) return(invisible(NULL))
  
  if ("Measure" %in% names(df)) {
    tab <- table(df$Measure, useNA = "ifany")
    cat("[DEBUG] Measures:", paste(names(tab), as.integer(tab), sep = "=", collapse = ", "), "\n")
  } else {
    cat("[DEBUG] Measures: <column 'Measure' missing>\n")
  }
  
  if ("Accident Year" %in% names(df)) {
    yrs <- suppressWarnings(as.integer(df[["Accident Year"]]))
    if (all(is.na(yrs))) cat("[DEBUG] Year range: NA..NA\n") else {
      rng <- suppressWarnings(range(yrs, na.rm = TRUE))
      cat("[DEBUG] Year range:", paste(rng, collapse = ".."), "\n")
    }
  } else {
    cat("[DEBUG] Year range: <column 'Accident Year' missing>\n")
  }
  
  if ("Actual" %in% names(df)) {
    cat("[DEBUG] Sum(Actual):", sum(df$Actual, na.rm = TRUE))
  } else {
    cat("[DEBUG] Sum(Actual): <col missing>")
  }
  if ("Expected" %in% names(df)) {
    cat(" | Sum(Expected):", sum(df$Expected, na.rm = TRUE), "\n")
  } else {
    cat(" | Sum(Expected): <col missing>\n")
  }
  invisible(NULL)
}

# Hardened: tolerate common synonyms before enforcing required core columns
ensure_columns <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(df)
  names(df) <- trimws(names(df))
  
  # Backfill Accident Year if not present
  if (!("Accident Year" %in% names(df))) {
    if ("accidentyear" %in% names(df)) {
      df[["Accident Year"]] <- suppressWarnings(as.integer(df[["accidentyear"]]))
    } else if ("AccidentYear" %in% names(df)) {
      df[["Accident Year"]] <- suppressWarnings(as.integer(df[["AccidentYear"]]))
    } else if ("accidentquarter" %in% names(df)) {
      aq <- suppressWarnings(as.numeric(df[["accidentquarter"]]))
      df[["Accident Year"]] <- suppressWarnings(as.integer(floor(aq / 100)))
    }
  }
  
  # Core columns required downstream
  core <- c("Actual","Expected","Accident Year","Product","Peril","Current or Prior")
  missing <- setdiff(core, names(df))
  
  # Be helpful: if 'Current or Prior' is missing, try to synthesise from a known flag
  if ("Current or Prior" %in% missing) {
    # Nothing reliable to derive it from by default — just ensure the column exists to avoid hard stop
    df[["Current or Prior"]] <- NA_character_
    missing <- setdiff(core, names(df))
  }
  
  if (length(missing) > 0) {
    stop(glue::glue("Missing required columns: {toString(missing)}"))
  }
  df
}
