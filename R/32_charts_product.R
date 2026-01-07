# R/32_charts_product.R — Product-level chart functions

plot_paid_ave_per_product <- function(paid_ave_df, out_root=NULL) {
  yrs <- ts_year_cols(paid_ave_df); if (!length(yrs)) return(list())
  out <- list()
  
  agg <- paid_ave_df %>%
    dplyr::group_by(Peril) %>%
    dplyr::summarise(dplyr::across(all_of(as.character(yrs)), ~ sum(.x, na.rm = TRUE)), .groups="drop")
  
  d_all <- agg %>%
    dplyr::filter(toupper(Peril)!="TOTAL") %>%
    tidyr::pivot_longer(cols=all_of(as.character(yrs)), names_to="Year", values_to="AE")
  
  p_all <- ggplot2::ggplot(d_all, ggplot2::aes(x=as.integer(Year), y=AE, colour=Peril)) +
    ggplot2::geom_line() + ggplot2::geom_point() +
    ggplot2::labs(title="Paid AvE – All products (perils)", x="Accident Year", y="A-E (£m)") +
    ggplot2::theme_minimal()
  
  out[[length(out)+1]] <- ggsave_raw(p_all, "Paid_AvE_all_products_lines",
                                     out_dir=ensure_dir(fs::path(out_root,"Paid_AvE")))
  
  for (prod in unique(paid_ave_df$Product)) {
    d <- paid_ave_df %>%
      dplyr::filter(Product==prod, toupper(Peril)!="TOTAL") %>%
      tidyr::pivot_longer(cols=all_of(as.character(yrs)), names_to="Year", values_to="AE")
    if (!nrow(d)) next
    
    p <- ggplot2::ggplot(d, ggplot2::aes(x=as.integer(Year), y=AE, colour=Peril)) +
      ggplot2::geom_line() + ggplot2::geom_point() +
      ggplot2::labs(title=paste0("Paid AvE – ", prod, " perils"),
                    x="Accident Year", y="A-E (£m)") +
      ggplot2::theme_minimal()
    
    safe_name <- gsub("[^A-Za-z0-9]+","_", prod)
    out[[length(out)+1]] <- ggsave_raw(p, paste0("Paid_AvE_", safe_name, "_perils_lines"),
                                       out_dir=fs::path(out_root,"Paid_AvE"))
  }
  out
}

heatmap_peril_amounts <- function(df_amt, col_value, title, fname, out_root) {
  d <- df_amt %>%
    dplyr::filter(Peril!="", toupper(Peril)!="TOTAL",
                  !`Class/Peril` %in% c("Grand Total","Check")) %>%
    dplyr::select(Product=`Class/Peril`, Peril, value=.data[[col_value]])
  if (!nrow(d)) return(NULL)
  
  p <- ggplot2::ggplot(d, ggplot2::aes(x=Peril, y=Product, fill=value)) +
    ggplot2::geom_tile() +
    ggplot2::labs(title=title, x=NULL, y=NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x=ggplot2::element_text(angle=45, hjust=1))
  
  ggsave_raw(p, fname, out_dir=ensure_dir(out_root))
}

bar_class_totals <- function(df_amt, col_value, title, fname, out_root) {
  d <- df_amt %>%
    dplyr::filter(Peril=="TOTAL", !`Class/Peril` %in% c("Grand Total","Check")) %>%
    dplyr::select(Product=`Class/Peril`, value=.data[[col_value]])
  if (!nrow(d)) return(NULL)
  
  p <- ggplot2::ggplot(d, ggplot2::aes(x=reorder(Product, value), y=value)) +
    ggplot2::geom_col() + ggplot2::coord_flip() +
    ggplot2::labs(title=title, x=NULL, y=col_value) +
    ggplot2::theme_minimal()
  
  ggsave_raw(p, fname, out_dir=ensure_dir(out_root))
}
