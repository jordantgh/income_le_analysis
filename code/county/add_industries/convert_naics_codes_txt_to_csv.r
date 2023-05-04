box::use(
  utils[read.delim, write.csv],
  glue[g = glue]
)


dir <- g("{globalenv()$project_root}/data/external_data/industry")
fname <- "naics_codes_1998_to_2002"

system(g("wget https://www2.census.gov/programs-surveys/susb/technical-documentation/{fname}.txt -O {dir}/{fname}.txt")) # nolint

system(g("awk 'NR>5 {{code=$1; $1=\"\"; gsub(/^[[:space:]]+/, \"\", $0); print code \"\t\" $0}}' {dir}/naics_codes_1998_to_2002.txt > {dir}/{fname}.tsv")) # nolint

data <- read.delim(g("{dir}/{fname}.tsv"),
  header = FALSE,
  col.names = c("NAICS_Code", "Description")
)

write.csv(data, g("{dir}/{fname}.csv"), row.names = FALSE)
