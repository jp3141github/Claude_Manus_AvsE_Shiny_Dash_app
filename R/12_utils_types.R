# R/12_utils_types.R — parsing + robust type coercion (safer dates, NA-safe numerics)

# Local %||% (in case 10_utils_core.R hasn't been sourced yet)
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(a, b) {
    # If a is NULL or zero-length, return b.
    if (is.null(a) || length(a) == 0) return(b)

    # Vector-safe check for "empty-like" atomic vectors (e.g. c(NA, NA) or c("", "")).
    # This prevents "condition has length > 1" errors when the operator's
    # result is used in an if() statement.
    if (is.atomic(a)) {
      is_empty <- if (is.character(a)) {
        all(is.na(a) | !nzchar(a))
      } else {
        all(is.na(a))
      }
      if (is_empty) return(b)
    }
    
    a
  }
}

# Convert a vector to numeric, handling:
# - Unicode minus, commas, £, spaces, non-breaking spaces
# - bracketed negatives "(123)" -> "-123"
# - keeps NA as NA (no implicit zeroing here)
to_float <- function(x) {
  if (is.numeric(x)) return(suppressWarnings(as.numeric(x)))
  t <- as.character(x)
  t <- stringr::str_replace_all(t, "[\u2212\u2012\u2013\u2014]", "-") |>
    stringr::str_replace_all("£", "") |>
    stringr::str_replace_all(",", "") |>
    stringr::str_replace_all("\u00A0", "") # Strip non-breaking spaces (from Excel)
  # kill repeated spaces, trim
  t <- stringr::str_squish(t)
  # bracketed negatives: "(123)" -> "-123"
  t <- stringr::str_replace_all(t, "\\(([^)]*)\\)", "-\\1")
  suppressWarnings(as.numeric(t))
}

# Parse a date column to Date with multiple common formats (NA-safe).
# Tries dmy/ymd/mdy with HMS/HM, then raw yyyymmdd, then Excel serials.
parse_projection_date_dateonly <- function(col) {
  col <- as.character(col)
  # Try a fast multi-order pass
  orders <- c("dmy HMS","dmy HM","dmy",
              "ymd HMS","ymd HM","ymd",
              "mdy HMS","mdy HM","mdy")
  parsed <- suppressWarnings(lubridate::parse_date_time(col, orders = orders, quiet = TRUE))
  # yyyymmdd (8-digit) fallback
  bad <- is.na(parsed) & grepl("^\\d{8}$", col)
  if (any(bad)) {
    parsed[bad] <- suppressWarnings(as.Date(col[bad], format = "%Y%m%d"))
  }
  # Excel serials (>= 1900-01-01)
  bad <- is.na(parsed) & grepl("^\\d{4,6}$", col)
  if (any(bad)) {
    serial <- suppressWarnings(as.numeric(col[bad]))
    serial_ok <- !is.na(serial) & serial > 0
    if (any(serial_ok)) {
      # Excel 1900 system (with the 1900 leap-year bug) — use as.Date(serial, origin="1899-12-30")
      parsed[bad][serial_ok] <- as.Date(serial[serial_ok], origin = "1899-12-30")
    }
  }
  as.Date(parsed)
}

# NOTE: relies on .force_text_ids_all() defined in R/11_utils_ids.R (uses fallback if absent)
coerce_types <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  
  # IDs as plain character (never factors)
  if (exists(".force_text_ids_all", mode = "function")) {
    df <- .force_text_ids_all(df)
  } else {
    for (nm in intersect(c("Product","Peril","Class/Peril","Segment","Segment (Group)","Measure"), names(df))) {
      df[[nm]] <- as.character(df[[nm]])
    }
  }
  
  # ---- Measure normalisation: exactly "Paid" / "Incurred"
  if ("Measure" %in% names(df)) {
    m0 <- tolower(trimws(as.character(df$Measure)))
  } else {
    obj_l <- tolower(trimws(as.character(df[["ObjectName"]] %||% "")))
    sec_l <- tolower(trimws(as.character(df[["Section"]]    %||% "")))
    m0 <- dplyr::case_when(
      stringr::str_detect(obj_l, "paid")  | stringr::str_detect(sec_l, "paid")  ~ "paid",
      stringr::str_detect(obj_l, "incur") | stringr::str_detect(sec_l, "incur") ~ "incurred",
      TRUE ~ NA_character_
    )
    m0[is.na(m0) & stringr::str_starts(obj_l, "paid")] <- "paid"
    m0[is.na(m0) & stringr::str_starts(obj_l, "inc")]  <- "incurred"
  }
  df[["Measure"]] <- dplyr::recode(m0,
                                   "paid" = "Paid",
                                   "incurred" = "Incurred",
                                   "incd" = "Incurred",
                                   "loss incurred" = "Incurred",
                                   .default = stringr::str_to_title(m0))
  
  # ---- Accident Year: create/clean/clamp -----------------------------------
  current_year_plus1 <- as.integer(format(Sys.Date(), "%Y")) + 1L
  if (!("Accident Year" %in% names(df))) {
    if ("accidentyear" %in% names(df)) {
      df[["Accident Year"]] <- suppressWarnings(as.integer(df[["accidentyear"]]))
    } else if ("AccidentYear" %in% names(df)) {
      df[["Accident Year"]] <- suppressWarnings(as.integer(df[["AccidentYear"]]))
    } else if ("accidentquarter" %in% names(df)) {
      aq <- suppressWarnings(as.numeric(df[["accidentquarter"]]))
      df[["Accident Year"]] <- suppressWarnings(as.integer(floor(aq / 100)))
    } else {
      df[["Accident Year"]] <- NA_integer_
    }
  } else {
    df[["Accident Year"]] <- suppressWarnings(as.integer(as.numeric(df[["Accident Year"]])))
  }
  ay <- df[["Accident Year"]]
  ay_ok <- !is.na(ay) & ay >= 1980 & ay <= current_year_plus1
  df[["Accident Year"]][!ay_ok] <- NA_integer_
  
  # ---- Current/Prior normalisation -----------------------------------------
  if ("Current or Prior" %in% names(df)) {
    cp <- toupper(trimws(as.character(df[["Current or Prior"]])))
    df[["Current or Prior"]] <- dplyr::recode(cp, "PRIOR" = "PY", "CURRENT" = "CY", .default = cp)
  }
  
  # ---- Numerics: keep NA as NA (no implicit zeroing here) -------------------
  if ("Actual"   %in% names(df))   df[["Actual"]]   <- to_float(df[["Actual"]])
  if ("Expected" %in% names(df))   df[["Expected"]] <- to_float(df[["Expected"]])
  
  # ---- IDs trimmed ----------------------------------------------------------
  if ("Product" %in% names(df)) df[["Product"]] <- trimws(as.character(df[["Product"]]))
  if ("Peril"   %in% names(df)) df[["Peril"]]   <- trimws(as.character(df[["Peril"]]))
  
  # ---- Derived A - E --------------------------------------------------------
  if (all(c("Actual","Expected") %in% names(df))) {
    df[["A - E"]] <- df[["Actual"]] - df[["Expected"]]
  }
  
  df
}
