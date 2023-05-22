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

import_csv_to_sqlite <- function(file_path, con) {
  table <- file_path_sans_ext(basename(file_path))

  # Check if the table already exists in the database
  if (dbExistsTable(con, table)) {
    cat(g("Table {table} already exists in the database. Skipping import.\n"))
    return()
  }

  data <- read_csv(file_path)
  dbWriteTable(con, table, data)
}

db_path <- "income_le.sqlite"
con <- dbConnect(SQLite(), db_path)

file_paths <- get_csv_files(g("{here::here()}/data/"))

for (file_path in file_paths) {
  import_csv_to_sqlite(file_path, con)
}

dbDisconnect(con)
