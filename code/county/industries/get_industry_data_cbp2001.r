rm(list = ls())
library(tidyverse)
library(glue)
g <- glue::glue

dir <- "data/external_data/industry"
fname <- "cbp01co"

system(g("wget https://www2.census.gov/programs-surveys/cbp/datasets/2001/{fname}.zip -O {dir}/{fname}.zip")) # nolint
system(g("unzip {dir}/{fname}.zip -d {dir}"))