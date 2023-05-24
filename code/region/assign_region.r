box::use(
  readr[read_csv, write_csv],
  magrittr[`%>%`],
  dplyr[mutate],
  DBI[dbConnect, dbWriteTable, dbExistsTable, dbDisconnect],
  RSQLite[SQLite],
  glue[g = glue]
)

dir <- g("{here::here()}")

add_region <- function(xwalk) {
  # Define the mapping of state abbreviations to regions
  region_mapping <- list(
    West = c(
      "AK", "AZ", "CA", "CO", "HI", "ID", "MT", "NV", "NM", "OR", "UT",
      "WA", "WY"
    ),
    Midwest = c(
      "IL", "IN", "IA", "KS", "MI", "MN", "MO", "NE", "ND", "OH",
      "SD", "WI"
    ),
    Northeast = c("CT", "ME", "MA", "NH", "NJ", "NY", "PA", "RI", "VT"),
    South = c(
      "AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS", "NC",
      "OK", "SC", "TN", "TX", "VA", "WV"
    )
  )

  # Function to return the region based on the state abbreviation
  state_to_region <- function(state_abbr) {
    for (region in names(region_mapping)) {
      if (state_abbr %in% region_mapping[[region]]) {
        return(region)
      }
    }
    return(NA)
  }

  xwalk %>%
    mutate(Region = sapply(stateabbrv, state_to_region))
}

# Import as a table in the SQLite database instead
db <- dbConnect(SQLite(), g("{dir}/income_le.sqlite"))
dbReadTable(db, "cty_cz_st_crosswalk") %>%
  add_region() %>%
  dbWriteTable(db, "cty_cz_st_crosswalk_with_region", overwrite = TRUE)

dbDisconnect(db)
