rm(list = ls())
library(tidyverse)
library(glue)
g <- glue::glue

dir <- "data/external_data/industry"
fname <- "cbp01co"

county_data <- read_csv(g("{dir}/{fname}.txt"))
county_data <- select(county_data, fipstate, fipscty, naics, emp)

# Filter to top level industries
top_level_industries <- county_data %>%
    filter(
        nchar(naics) == 6,
        substr(naics, 3, 6) == "----",
        substr(naics, 1, 2) != "--"
    ) %>%
    mutate(
        # get rid of leading 0s in state fips
        # (needed to join with Chetty data)
        fipstate = as.character(as.numeric(fipstate)),
        # get rid of trailing "--" in naics
        naics = substr(naics, 1, 2)
    )

# Find the dominant industry for each county
dominant_industry <- top_level_industries %>%
    group_by(fipstate, fipscty) %>%
    top_n(1, emp) %>%
    ungroup()

naics_descriptions <- read_csv(g("{dir}/naics_codes_1998_to_2002.csv"))
colnames(naics_descriptions) <- c("naics", "description")

# remove the "ranges" (e.g. "31-33") from the naics column
naics_clean <- naics_descriptions[-1, ] %>%
    separate(naics, into = c("start", "end"), sep = "-") %>%
    mutate(end = ifelse(is.na(end), start, end)) %>%
    rowwise() %>%
    mutate(naics = list(seq(start, end)), .before = description) %>%
    ungroup() %>%
    unnest(naics) %>%
    mutate(naics = as.character(naics)) %>%
    select(-start, -end)

# join with naics code tables with descriptions
dominant_industry <- left_join(dominant_industry,
    naics_clean,
    by = "naics"
)

top_level_industries <- left_join(top_level_industries,
    naics_clean,
    by = "naics"
)

# concatenate the state and county fips (to match Chetty tables)
dominant_industry <- dominant_industry %>%
    mutate(cty = g("{fipstate}{fipscty}"), .before = naics) %>%
    select(-fipstate, -fipscty)

top_level_industries <- top_level_industries %>%
    mutate(cty = g("{fipstate}{fipscty}"), .before = naics) %>%
    select(-fipstate, -fipscty)

# save
derived_dir <- "data/derived_tables/county"

write_csv(
    dominant_industry,
    g("{derived_dir}/county_dominant_industries_2001.csv")
)
write_csv(
    top_level_industries,
    g("{derived_dir}/county_top_industries_2001.csv")
)
