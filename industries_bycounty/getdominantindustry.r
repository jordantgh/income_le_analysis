rm(list = ls())
try(setwd("industry_data"))
library(tidyverse)

system("wget https://www2.census.gov/programs-surveys/cbp/datasets/2001/cbp01co.zip")

system("unzip cbp01co.zip")

county_data <- read_csv("cbp01co.txt")

county_data <- select(county_data, fipstate, fipscty, naics, emp)

# Filter to top level industries
top_level_industries <- county_data %>%
    filter(
        nchar(naics) == 6,
        substr(naics, 3, 6) == "----",
        substr(naics, 1, 2) != "--"
    )

# Find the dominant industry for each county
dominant_industry <- top_level_industries %>%
    group_by(fipstate, fipscty) %>%
    top_n(1, emp) %>%
    ungroup()

dominant_industry <- dominant_industry %>%
    mutate(
        # get rid of leading 0s in state fips
        # (needed to join with Chetty data)
        fipstate = as.character(as.numeric(fipstate)),
        # get rid of trailing "--" in naics
        naics = substr(naics, 1, 2)
    )

naics_descriptions <- read_csv("naics_codes_1998_to_2002.csv")
colnames(naics_descriptions) <- c("naics", "description")

# remove the naics ranges
naics_clean <- naics_descriptions[-1, ] %>%
    separate(naics, into = c("start", "end"), sep = "-") %>%
    mutate(end = ifelse(is.na(end), start, end)) %>%
    rowwise() %>%
    mutate(naics = list(seq(start, end)), .before = description) %>%
    ungroup() %>%
    unnest(naics) %>%
    mutate(naics = as.character(naics)) %>%
    select(-start, -end)


dominant_industry <- left_join(dominant_industry,
    naics_clean,
    by = "naics"
)

write_csv(dominant_industry, "county_dominant_industries_2001.csv")