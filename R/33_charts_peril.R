# R/33_charts_peril.R — Peril-level chart functions

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
