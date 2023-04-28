setwd("/home/jtaylor/Projects/income_le_analysis/industry_data/")

system("wget https://www2.census.gov/programs-surveys/susb/technical-documentation/naics_codes_1998_to_2002.txt")
system("awk 'NR>5 {code=$1; $1=\"\"; gsub(/^[[:space:]]+/, \"\", $0); print code \"\t\" $0}' naics_codes_1998_to_2002.txt > naics_codes_1998_to_2002.tsv")

data <- read.delim("naics_codes_1998_to_2002.tsv",
    header = FALSE,
    col.names = c("NAICS_Code", "Description")
)

write.csv(data, "naics_codes_1998_to_2002.csv", row.names = FALSE)
