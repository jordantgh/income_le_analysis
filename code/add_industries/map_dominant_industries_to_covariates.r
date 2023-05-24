box::use(
  DBI[dbConnect, dbReadTable, dbWriteTable, dbDisconnect],
  RSQLite[SQLite],
  magrittr[`%>%`],
  dplyr[select, left_join],
  glue[g = glue]
)

# create a connection
db <- dbConnect(SQLite(), g("{here::here()}/income_le.sqlite"))

# load tables from the SQLite db
covariates <- dbReadTable(db, "t12_countCovariates")
industries <- dbReadTable(db, "county_dominant_industries_2001")

# remove nonessential columns from industries
industries <- industries %>%
  select(-industry_naics_code)

covariates <- left_join(covariates, industries, by = "cty")

# write the final table to the SQLite db
dbWriteTable(db,
  "countyCovariates_with_industries",
  covariates,
  overwrite = TRUE
)

# close the connection
dbDisconnect(db)
