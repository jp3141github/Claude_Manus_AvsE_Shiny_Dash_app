# ui.R — glue wrapper that uses UI parts defined under R/

# By now, global.R has already sourced:
# - R/03_js_css_assets.R: header_css, css_overrides, js_code
# - R/60_ui_components.R: sidebar_controls (and sometimes `ui <- page_sidebar(...)`)
# - R/61_ui_results.R / R/62_ui_charts.R: any extra UI helpers you defined

# If 60_ui_components.R already defines `ui <- page_sidebar(...)`, use it:
if (exists("ui", inherits = TRUE)) {
  ui_bundle <- ui

} else {
  # Build a minimal page from the exported bits
  header_css_val <- if (exists("header_css", inherits = TRUE)) header_css else NULL
  sidebar_val    <- if (exists("sidebar_controls", inherits = TRUE)) sidebar_controls else NULL
  css_extra      <- if (exists("css_overrides", inherits = TRUE)) css_overrides else NULL
  js_extra       <- if (exists("js_code", inherits = TRUE)) tags$script(htmltools::HTML(js_code)) else NULL

  ui_bundle <- bslib::page_sidebar(
    title = "AvE Tracker (modular)",
    sidebar = sidebar_val,
    # status/header meta
    uiOutput("full_header_block"),

    # lightweight busy overlay
    tags$div(id = "busy-overlay", class = "", tags$div(class = "spinner")),

    # main content tabs (server populates these with UI via renderUI)
    bslib::navset_tab(
      bslib::nav_panel("Input Data", uiOutput("preview_card")),
      bslib::nav_panel("Results",    uiOutput("results_tabs_ui")),
      bslib::nav_panel("Charts",     uiOutput("charts_ui")),
      bslib::nav_panel("Checks", uiOutput("checks_ui")),  # <— NEW TAB
      id = "tabs_main"
    ),

    # header css from R/03z_assets_bind.R (ok if NULL)
    header = header_css_val
  )

  # Append optional global CSS/JS if present
  ui_bundle <- htmltools::tagList(ui_bundle, css_extra, js_extra)
}

# Shiny expects 'ui', not 'ui_bundle', so assign it
ui <- ui_bundle
