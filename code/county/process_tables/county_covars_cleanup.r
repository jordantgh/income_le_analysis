box::use(
  DBI[dbConnect, dbGetQuery, dbDisconnect],
  RSQLite[SQLite],
  glue[g = glue],
  ggplot2[...],
  dplyr[...],
  purrr[map, pmap_dfc],
  utils[head, tail],
  stats[sd, lm],
  mice[md.pattern, mice, complete],
  tibble[as_tibble]
)


db <- dbConnect(SQLite(), g("{globalenv()$project_root}/income_le.sqlite"))

tables <- dbGetQuery(
    db,
    "
    SELECT name FROM sqlite_schema
    WHERE type='table'
    ORDER BY name;
    "
)

# get the columns for the countyCovariates_with_industries table
covariateschema <- dbGetQuery(
    db, "
    PRAGMA table_info(countyCovariates_with_industries);
    "
)

countyleschema <- dbGetQuery(
    db, "
    PRAGMA table_info(t11_countyLE_bygender_byincquartile);
    "
)

le_agg <- dbGetQuery(
    db, "
    SELECT
    cty,
    cty_pop2000,

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

cov_table <- dbGetQuery(
    db,
    "
    SELECT
    cty,

    /* Economic variables */
    gini99,
    hhinc00,
    unemp_rate,
    cs00_seg_inc,
    cs00_seg_inc_pov25,
    cs00_seg_inc_aff75,
    inc_share_1perc,
    median_house_value,

    /* Demographic variables */
    pop_density,
    mig_inflow,
    cs_frac_black,
    cs_frac_hisp,
    cs_born_foreign,

    /* Health variables */
    cur_smoke_q1,
    cur_smoke_q2,
    cur_smoke_q3,
    cur_smoke_q4,
    bmi_obese_q1,
    bmi_obese_q2,
    bmi_obese_q3,
    bmi_obese_q4

    FROM countyCovariates_with_industries;

    "
)

full_covariates <- dbGetQuery(
    db, "
    SELECT * FROM countyCovariates_with_industries;
    "
)

dbDisconnect(db)

# Join the two tables
le_covars <- left_join(le_agg, cov_table, by = "cty")

# clean the joined table

# (no dups, any(duplicated(le_covars)) = FALSE)

# check out of range values
map(le_covars, \(x) print(summary(x)))

# replace zeros with NAs (none of the variables should plausibly be zero)
le_covars[le_covars == 0] <- NA

# replace >= 1 in fractional columns which have them with NAs
fcols_upper <- c(
    "gini99",
    "cur_smoke_q1",
    "cur_smoke_q4",
    "bmi_obese_q1",
    "bmi_obese_q2",
    "bmi_obese_q3"
)

map(fcols_upper, \(col) le_covars[[col]][le_covars[[col]] >= 1] <<- NA)

# check missing values
missing_pattern <- md.pattern(le_covars) %>% as_tibble()

# select variables with missing values
have_missing <- missing_pattern %>%
    select(where(~ tail(., 1) > 0)) %>%
    names() %>%
    head(-1) # remove md.pattern summary column

# filter df for regression imputation
df_for_cor <- le_covars %>% select(-c(1, 2))

# store original summary statistics prior to scaling
original_means <- map(df_for_cor, \(x) mean(x, na.rm = TRUE))
original_sds <- map(df_for_cor, \(x) sd(x, na.rm = TRUE))

# convert columns to z scores
df_for_cor <- df_for_cor %>% mutate_all(~ as.numeric(scale(.)))

# impute with mice
imp <- mice(df_for_cor, m = 1, maxit = 20, seed = 123, printFlag = FALSE)
## n.b. checked convergence with plot(imp), looks good at 20 iterations

# remove id columns
imputed_z <- complete(imp, action = "long") %>% select(-c(1, 2))

# convert back to original scale
final_imputed <- pmap_dfc(
    list(imputed_z, original_sds, original_means),
    function(z_data, sd, mean) {
        z_data * sd + mean
    }
)


# add the cty and cty_pop2000 columns back in
final_imputed <- final_imputed %>%
    as_tibble() %>%
    mutate(
        cty = le_covars$cty,
        cty_pop2000 = le_covars$cty_pop2000,
        .before = le_agg_q1
    )

# compute lm weight by population
mod <- lm(
    formula = "bmi_obese_q3 ~ bmi_obese_q2",
    data = final_imputed[final_imputed$bmi_obese_q3 > 0 &
        final_imputed$bmi_obese_q2 > 0, ],
    weights = cty_pop2000
)


# Test plot
plot <- ggplot(
    final_imputed,
    aes(x = bmi_obese_q3, y = bmi_obese_q2)
) +
    geom_point(aes(size = cty_pop2000), shape = 16, alpha = 0.35) +
    geom_abline(
        intercept = mod$coefficients[1],
        slope = mod$coefficients[2],
        color = "red"
    ) +
    labs(x = "Obesity rate (q3)", y = "Obesity rate (q2)") +
    theme_bw()