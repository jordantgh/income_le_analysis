box::use(
  DBI[dbConnect, dbGetQuery, dbDisconnect],
  RSQLite[SQLite]
)

get_cty_le_agg <- function(db) {
  return(dbGetQuery(
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
  ))
}

get_cty_covariates <- function(db) {
  return(dbGetQuery(
    db, "
    SELECT * FROM countyCovariates_with_industries;
    "
  ))
}

get_cz_le_agg <- function(db) {
  return(dbGetQuery(
    db, "
    SELECT
    cz,

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

    FROM t6_czLE_bygender_byincquartile;
    "
  ))
}

get_cz_covariates <- function(db) {
  return(dbGetQuery(
    db, "
    SELECT * FROM t10_czCovariates;
    "
  ))
}

get_cty_crosswalk <- function(db) {
  return(dbGetQuery(
    db, "
    SELECT cty, Region FROM cty_cz_st_crosswalk_with_region;
    "
  ))
}

get_cz_crosswalk <- function(db) {
  return(dbGetQuery(
    db, "
    SELECT DISTINCT cz, Region FROM cty_cz_st_crosswalk_with_region;
    "
  ))
}
