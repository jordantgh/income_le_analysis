box::use(
  utils[read.delim],
  glue[g = glue],
  magrittr[`%>%`],
  DBI[dbConnect, dbWriteTable, dbExistsTable, dbDisconnect],
  RSQLite[SQLite]
)

dir <- g("{here::here()}/data/external_data/industry")
fname <- "naics_codes_1998_to_2002"

paste0(
  "wget ",
  "https://www2.census.gov/programs-surveys/susb/technical-documentation/",
  "{fname}.txt ",
  "-O {dir}/{fname}.txt"
) %>%
  g() %>%
  system()

# we use .tsv instead of .csv because the file contains commas
# in the description column
paste(
  "awk 'NR>5 {{code=$1; $1=\"\"; gsub(/^[[:space:]]+/, \"\", $0);",
  "print code \"\t\" $0}}'",
  "{dir}/{fname}.txt > {dir}/{fname}.tsv"
) %>%
  g() %>%
  system()

data <- read.delim(g("{dir}/{fname}.tsv"),
  header = FALSE,
  col.names = c("NAICS_Code", "Description")
)

db_file <- g("{here::here()}/income_le.sqlite")
db <- dbConnect(SQLite(), db_file)

dbWriteTable(db, fname, data, overwrite = TRUE)

dbDisconnect(db)