box::use(
    dplyr[...],
    readr[...],
    glue[g = glue]
)

dir <- g("{getOption('project_root')}/data")
covariates <- read_csv(g("{dir}/chetty_online_tables/county/t12_countCovariates.csv")) # nolint

industries <- read_csv(g("{dir}/derived_tables/county/county_dominant_industries_2001.csv")) # nolint

# remove nonessential columns from industries
industries <- industries %>%
    select(-industry_naics_code)

covariates <- left_join(covariates, industries, by = "cty")

write_csv(covariates, g("{dir}/derived_tables/county/countyCovariates_with_industries.csv")) # nolint
