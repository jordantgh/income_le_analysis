box::use(
  utils[read.delim, write.csv],
  glue[g = glue],
  DBI[dbConnect, dbWriteTable, dbExistsTable, dbDisconnect],
  RSQLite[SQLite]
)

dir <- g("{here::here()}/data/external_data/industry")
fname <- "naics_codes_1998_to_2002"

system(g("wget https://www2.census.gov/programs-surveys/susb/technical-documentation/{fname}.txt -O {dir}/{fname}.txt")) # nolint

system(g("awk 'NR>5 {{code=$1; $1=\"\"; gsub(/^[[:space:]]+/, \"\", $0); print code \"\t\" $0}}' {dir}/naics_codes_1998_to_2002.txt > {dir}/{fname}.tsv")) # nolint

data <- read.delim(g("{dir}/{fname}.tsv"),
  header = FALSE,
  col.names = c("NAICS_Code", "Description")
)

db_file <- g("{here::here()}/income_le.sqlite")

db <- dbConnect(SQLite(), db_file)
if (!dbExistsTable(db, fname)) {
  dbWriteTable(db, fname, data)
  dbDisconnect(db)
} else {
  cat(g("Table {fname} already exists in the database. Skipping import.\n")) # nolint
  dbDisconnect(db)
}
