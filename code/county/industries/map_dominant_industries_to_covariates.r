library(tidyverse)

covariates <- read_csv("data/chetty_online_tables/county/t12_countCovariates.csv") #nolint

industries <- read_csv("data/external_data/industry/county_dominant_industries_2001.csv") #nolint

covariates <- left_join(covariates, industries, by = "cty")

write_csv(covariates, "data/derived_tables/county/countyCovariates_with_industries.csv") #nolint
