box::use(
    dplyr[...],
    readr[...],
    tidyr[...],
    glue[g = glue],
    DBI[...],
    RSQLite[SQLite]
)

db_file <- g("{here::here()}/income_le.sqlite")

county_data <- dbConnect(SQLite(), db_file) %>%
    dbGetQuery("
    SELECT

    fipstate,
    fipscty,
    naics,
    emp

    FROM complete_county_industries_2001;"
    )

# Filter to top level industries
top_level_industries <- county_data %>%
    filter(
        nchar(naics) == 6,
        substr(naics, 3, 6) == "----",
        substr(naics, 1, 2) != "--"
    ) %>%
    mutate(
        # remove leading 0s in state fips (needed to join w/ Chetty data)
        fipstate = as.character(as.numeric(fipstate)),
        # remove trailing "--" in naics
        naics = substr(naics, 1, 2)
    )

# Find the dominant industry for each county
dominant_industry <- top_level_industries %>%
    group_by(fipstate, fipscty) %>%
    top_n(1, emp) %>%
    ungroup()

naics_descriptions <- dbConnect(SQLite(), db_file) %>%
    dbGetQuery("
    SELECT

    NAICS_Code as naics,
    Description as description

    FROM naics_codes_1998_to_2002;"
    )

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
) %>%
    select(fipstate, fipscty, description, naics, emp) %>%
    rename(
        top_industry = description,
        industry_naics_code = naics,
        top_industry_employment = emp
    )

top_level_industries <- left_join(top_level_industries,
    naics_clean,
    by = "naics"
) %>%
    select(fipstate, fipscty, description, naics, emp) %>%
    rename(
        industry = description,
        industry_naics_code = naics,
        industry_employment = emp
    )

# concatenate the state and county fips (to match Chetty tables)
dominant_industry <- dominant_industry %>%
    mutate(cty = g("{fipstate}{fipscty}"), .before = top_industry) %>%
    select(-fipstate, -fipscty)

top_level_industries <- top_level_industries %>%
    mutate(cty = g("{fipstate}{fipscty}"), .before = industry) %>%
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
