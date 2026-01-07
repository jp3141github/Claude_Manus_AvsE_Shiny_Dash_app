# R/11_utils_ids.R — ID coercion + guards

.force_text_ids_all <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  for (nm in intersect(c("Product","Peril","Class/Peril","Segment (Group)"), names(df)))
    df[[nm]] <- as.character(df[[nm]])
  df
}

.force_char_ids <- function(df) {
  if (is.null(df)) return(df)
  for (nm in c("Product","Peril","Class/Peril","Segment (Group)")) {
    if (!(nm %in% names(df))) df[[nm]] <- NA_character_
    df[[nm]] <- as.character(ifelse(is.na(df[[nm]]), "", df[[nm]]))
  }
  df
}

sanitize_ids <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  if (!"Product" %in% names(df)) df$Product <- ""
  if (!"Peril"   %in% names(df)) df$Peril   <- ""
  df$Product <- ifelse(is.na(df$Product), "", as.character(df$Product))
  df$Peril   <- ifelse(is.na(df$Peril),   "", as.character(df$Peril))
  df
}

# ensure presence of key ID columns even on 0-row frames
ensure_id_cols <- function(df) {
  if (!"Peril" %in% names(df))            df$Peril <- ""
  if (!"Class/Peril" %in% names(df))      df$`Class/Peril` <- ""
  if (!"Segment (Group)" %in% names(df))  df$`Segment (Group)` <- ""
  df
}

# Text & NA guard used by orchestration to stabilise percent tables
.ids_text_guard <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  for (nm in intersect(c("Product","Peril","Class/Peril","Segment (Group)"), names(df))) {
    df[[nm]] <- trimws(as.character(df[[nm]]))
    df[[nm]][is.na(df[[nm]])] <- ""
  }
  if ("Peril" %in% names(df)) {
    df <- dplyr::filter(df, Peril == "" | toupper(Peril) == "TOTAL" | grepl("[A-Za-z]", Peril))
  }
  df
}
