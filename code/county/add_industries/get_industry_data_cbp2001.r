box::use(glue[g = glue])

dir <- g("{globalenv()$project_root)/data/external_data/industry")
fname <- "cbp01co"

system(g("wget https://www2.census.gov/programs-surveys/cbp/datasets/2001/{fname}.zip -O {dir}/{fname}.zip")) # nolint
system(g("unzip {dir}/{fname}.zip -d {dir}"))