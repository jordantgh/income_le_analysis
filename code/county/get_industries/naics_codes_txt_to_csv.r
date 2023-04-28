rm(list = ls())
library(glue)

dir <- "data/external_data/industry"
fname <- "naics_codes_1998_to_2002"

system(glue("wget https://www2.census.gov/programs-surveys/susb/technical-documentation/naics_codes_1998_to_2002.txt -O {dir}/{fname}.txt")) # nolint

system(glue("awk 'NR>5 {{code=$1; $1=\"\"; gsub(/^[[:space:]]+/, \"\", $0); print code \"\t\" $0}}' {dir}/naics_codes_1998_to_2002.txt > {dir}/{fname}.tsv")) # nolint

data <- read.delim(glue("{dir}/{fname}.tsv"),
  header = FALSE,
  col.names = c("NAICS_Code", "Description")
)

write.csv(data, glue("{dir}/{fname}.csv"), row.names = FALSE)