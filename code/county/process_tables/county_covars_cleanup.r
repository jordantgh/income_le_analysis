box::use(
    DBI[dbConnect, dbGetQuery, dbDisconnect],
    RSQLite[SQLite],
    glue[g = glue],
    ggplot2[...],
    dplyr[...],
    purrr[keep, map, pmap_dfc],
    utils[head, tail],
    stats[sd, lm],
    mice[md.pattern, mice, complete],
    tibble[as_tibble]
)

dir <- getOption("project_root")
db <- dbConnect(SQLite(), g("{dir}/income_le.sqlite"))

le_agg <- dbGetQuery(
    db, "
    SELECT
    cty,

    /* Calculate weighted average for point estimates */
    (le_agg_q1_F * count_q1_F + le_agg_q1_M * count_q1_M) /
    (count_q1_F + count_q1_M) as le_agg_q1,
    (le_agg_q2_F * count_q2_F + le_agg_q2_M * count_q2_M) /
    (count_q2_F + count_q2_M) as le_agg_q2,
    (le_agg_q3_F * count_q3_F + le_agg_q3_M * count_q3_M) /
    (count_q3_F + count_q3_M) as le_agg_q3,
    (le_agg_q4_F * count_q4_F + le_agg_q4_M * count_q4_M) /
    (count_q4_F + count_q4_M) as le_agg_q4,

    /* Calculate combined standard errors */
    SQRT((POWER(sd_le_agg_q1_F, 2) * count_q1_F +
        POWER(sd_le_agg_q1_M, 2) * count_q1_M) /
    (count_q1_F + count_q1_M)) as sd_le_agg_q1,

    SQRT((POWER(sd_le_agg_q2_F, 2) * count_q2_F +
        POWER(sd_le_agg_q2_M, 2) * count_q2_M) /
    (count_q2_F + count_q2_M)) as sd_le_agg_q2,

    SQRT((POWER(sd_le_agg_q3_F, 2) * count_q3_F +
        POWER(sd_le_agg_q3_M, 2) * count_q3_M) /
    (count_q3_F + count_q3_M)) as sd_le_agg_q3,

    SQRT((POWER(sd_le_agg_q4_F, 2) * count_q4_F +
        POWER(sd_le_agg_q4_M, 2) * count_q4_M) /
    (count_q4_F + count_q4_M)) as sd_le_agg_q4

    FROM t11_countyLE_bygender_byincquartile;
    "
)

full_covariates <- dbGetQuery(
    db, "
    SELECT * FROM countyCovariates_with_industries;
    "
)

crosswalk <- dbGetQuery(
    db, "
    SELECT cty, Region FROM cty_cz_st_crosswalk_with_region;
    "
)

dbDisconnect(db)

# Join the tables

unwanted_vars <- c(
    "csa",
    "csa_name",
    "cbsa",
    "cbsa_name",
    "naics",
    "tuition"
)

non_imputed <- c(
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
    "description",
    "taxrate",
    "tax_st_diff_top20"
    )

original_df <- left_join(le_agg, full_covariates, by = "cty") %>%
    left_join(crosswalk, by = "cty")

le_covars <- original_df %>%
    select(!all_of(c(non_imputed, unwanted_vars)))

# clean the joined table

# check out of range values
overview <- map(
    le_covars,
    \(col) g("MAX: {max(col, na.rm = TRUE)} \n MIN: {min(col, na.rm = TRUE)}")
)

# replace <= 0 with NAs (none of the variables should plausibly be zero or less)

# columns where <= 0 is plausible
leq_0_not_NA <-
    "taxrate|tax_st_diff_top20|subcty_exp_pc|score_r|lf_d|pop_d|scap_ski|_z"

le_covars <- le_covars %>%
    mutate(across(!matches(leq_0_not_NA), \(x) replace(x, x <= 0, NA)))

# replace >= 1 in fractional columns which have them with NAs

# select columns with potentially out of bounds fractional values
potential_cols <- le_covars %>%
    select_if(\(x) max(x, na.rm = TRUE) >= 1) %>%
    names()

potential_cols <- overview %>% keep(names(.) %in% potential_cols)

# matching cols regex
greq_1_NA <- "gini|inc_share_1perc|cs00_|cur_smoke|bmi_obese|exercise"

# replace with NAs
le_covars <- le_covars %>%
    mutate(across(matches(greq_1_NA), \(x) replace(x, x >= 1, NA)))

# remove cols with excess missingness (> 5%)
le_covars <- le_covars %>% select_if(\(x) {
    sum(is.na(x)) / nrow(le_covars) < 0.05
})


# store original summary statistics prior to scaling
original_means <- le_covars %>% map(\(col) mean(col, na.rm = TRUE))
original_sds <- le_covars %>% map(\(col) sd(col, na.rm = TRUE))

# convert columns to z scores
le_covars <- le_covars %>% mutate(across(
    everything(),
    \(col) as.numeric(scale(col))
))

# impute with mice
imp <- mice(le_covars, m = 1, maxit = 20, seed = 123, printFlag = FALSE)
## n.b. checked convergence with plot(imp), looks good at 20 iterations

# remove mice-inserted cols
imputed_z <- complete(imp, action = "long") %>% select(-c(1, 2))

# convert back to original scale
final_imputed <- pmap_dfc(
    list(imputed_z, original_sds, original_means),
    function(z_data, sd, mean) {
        z_data * sd + mean
    }
)

# add the id columns back
final_imputed <- original_df %>%
    select(all_of(non_imputed)) %>%
    bind_cols(final_imputed)

outdir <- g("{dir}/data/derived_tables/temp")
readr::write_csv(final_imputed, g("{outdir}/final_imputed.csv"))
