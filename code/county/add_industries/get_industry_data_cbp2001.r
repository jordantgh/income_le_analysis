box::use(
    glue[g = glue],
    DBI[dbConnect, dbWriteTable,dbExistsTable, dbDisconnect],
    RSQLite[SQLite],
    readr[read_csv]
)

dir <- g("{here::here()}/data/external_data/industry")
url <- g("https://www2.census.gov/programs-surveys/cbp/datasets/2001/cbp01co.zip") # nolint

system(g("wget {url} -O {dir}/{fname}.zip"))
system(g("unzip {dir}/{fname}.zip -d {dir}"))
system(g("mv {dir}/{fname}.txt {dir}/{fname}.csv"))

db_file <- g("{dir}/income_le.sqlite")
table_name <- "complete_county_industries_2001"

db <- dbConnect(SQLite(), db_file)

if (!dbExistsTable(db, table_name)) {
    dbWriteTable(db, table_name, read_csv(g("{dir}/{fname}.csv")))
    dbDisconnect(db)
} else {
    cat(g("Table {table_name} already exists in the database. Skipping import.\n")) # nolint
    dbDisconnect(db)
}
