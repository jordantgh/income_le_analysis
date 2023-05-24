box::use(
  DBI[...],
  tools[...],
  readr[...],
  RSQLite[SQLite],
  glue[g = glue]
)

get_csv_files <- function(path) {
  files <- list.files(path, full.names = TRUE, recursive = TRUE)
  return(files[grep("\\.csv$", files)])
}

import_csv_to_sqlite <- function(file_path, db) {
  table <- file_path_sans_ext(basename(file_path))

  if (dbExistsTable(db, table)) {
    cat(g("Table {table} already exists in the database. Skipping import.\n"))
    return()
  }

  data <- read_csv(file_path)
  dbWriteTable(db, table, data)
}

db_path <- "income_le.sqlite"
db <- dbConnect(SQLite(), db_path)

file_paths <- get_csv_files(g("{here::here()}/data/"))

for (file_path in file_paths) {
  import_csv_to_sqlite(file_path, db)
}

dbDisconnect(db)
