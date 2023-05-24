box::use(
  glue[g = glue],
  DBI[dbConnect, dbWriteTable, dbExistsTable, dbDisconnect],
  RSQLite[SQLite],
  readr[read_csv]
)

dir <- g("{here::here()}/data/external_data/industry")
url <- g("https://www2.census.gov/programs-surveys/cbp/datasets/2001/cbp01co.zip") # nolint

system(g("wget {url} -O {dir}/cbp01co.zip"))
system(g("unzip {dir}/cbp01co.zip -d {dir}"))

db_file <- g("{here::here()}/income_le.sqlite")
table_name <- "complete_county_industries_2001"

db <- dbConnect(SQLite(), db_file)

dbWriteTable(db, table_name, read_csv(g("{dir}/cbp01co.txt")), overwrite = TRUE)
dbDisconnect(db)
