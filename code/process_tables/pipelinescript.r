box::use(
  DBI[dbConnect, dbGetQuery, dbWriteTable, dbDisconnect],
  RSQLite[SQLite],
  glue[g = glue],
  ggplot2[...],
  dplyr[...],
  purrr[keep, map, pmap_dfc],
  utils[head, tail],
  stats[sd, lm],
  mice[md.pattern, mice, complete],
  tibble[as_tibble],
  rlang[parse_expr],
  . / code / process_tables / queries[...],
  . / code / process_tables / cleanup_functions[...],
  . / code / process_tables / classes[...]
)

dir <- here::here()
db <- dbConnect(SQLite(), g("{dir}/income_le.sqlite"))

cty_le_agg <- get_cty_le_agg(db)
cty_covariates <- get_cty_covariates(db)
cz_le_agg <- get_cz_le_agg(db)
cz_covariates <- get_cz_covariates(db)
cty_crosswalk <- get_cty_crosswalk(db)
cz_crosswalk <- get_cz_crosswalk(db)

dbDisconnect(db)

cty_data <- left_join(cty_le_agg, cty_covariates, by = "cty") %>%
  left_join(cty_crosswalk, by = "cty")

cz_data <- left_join(cz_le_agg, cz_covariates, by = "cz") %>%
  left_join(cz_crosswalk, by = "cz")

cty_unwanted <- c(
  "csa",
  "csa_name",
  "cbsa",
  "cbsa_name",
  "tuition"
)

cty_non_imputed <- c(
  "cty",
  "county_name",
  "cz",
  "cz_name",
  "cz_pop2000",
  "state_id",
  "stateabbrv",
  "statename",
  "Region",
  "intersects_msa",
  "top_industry",
  "top_industry_employment"
)

cty_covars <- cty_data %>% StripCols(c(cty_unwanted, cty_non_imputed))

cz_non_imputed <- c(
  "cz",
  "czname",
  "pop2000",
  "fips",
  "stateabbrv",
  "statename",
  "Region",
  "taxrate",
  "tax_st_diff_top20"
)

cz_covars <- cz_data %>% StripCols(cz_non_imputed)

boundary_conditions <- ConstraintHolder$new("boundary_conditions")
boundary_conditions$addConstraint(0, comparison = "<=", name = "upto_0")
boundary_conditions$addConstraint(1, comparison = ">=", name = "over_1")

cty_suspect_cols <- get_filter_containers(cty_covars, boundary_conditions)
cz_suspect_cols <- get_filter_containers(cz_covars, boundary_conditions)


cty_leq_0 <- cty_suspect_cols$getColCheck("upto_0")$getPotentialCols()
cty_geq_1 <- cty_suspect_cols$getColCheck("over_1")$getPotentialCols()
cz_leq_0 <- cz_suspect_cols$getColCheck("upto_0")$getPotentialCols()
cz_geq_1 <- cz_suspect_cols$getColCheck("over_1")$getPotentialCols()

leq_0_not_NA <- cty_suspect_cols$getColCheck("upto_0")$createColFilter(
  pattern = "tax|subcty_exp_pc|score_r|lf_d|pop_d|scap_ski|_z",
  filterNonMatches = TRUE
)

greq_1_NA <- cz_suspect_cols$getColCheck("over_1")$createColFilter(
  pattern = "gini|inc_share_1perc|cs00_|cur_smoke|bmi_obese|exercise"
)

filters <- list(leq_0_not_NA, greq_1_NA)

cty_impute <- process_imputation(cty_covars, filters, cty_data, cty_non_imputed)
cz_impute <- process_imputation(cz_covars, filters, cz_data, cz_non_imputed)

db <- dbConnect(SQLite(), g("{dir}/income_le.sqlite"))

dbWriteTable(db, "final_imputed_county", cty_impute, overwrite = TRUE)
dbWriteTable(db, "final_imputed_cz", cz_impute, overwrite = TRUE)

dbDisconnect(db)