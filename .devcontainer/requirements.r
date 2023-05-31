dependencies <- c(
  #dev (vscode) dependencies:
  "languageserver",
  "httpgd",
  #app dependencies:
  "here",
  "box",
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "ggplot2",
  "plotly",
  "ggbeeswarm",
  "ggprism",
  "readr",
  "leaflet",
  "leaflet.providers",
  "dplyr",
  "purrr",
  "sf",
  "DBI",
  "RSQLite",
  "glue",
  "utils",
  "stats",
  "mice",
  "tibble",
  "rlang",
  "tidyr",
  "tools",
  "magrittr"
)

new <- dependencies[!(dependencies %in% installed.packages()[, "Package"])]

if (length(new)) install.packages(new)
