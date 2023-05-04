# this script will orchestrate all the other scripts
# and set up the environment

project_root <- here::here()
options(box.path = project_root)

box::use(code/county/industries/convert_naics_codes_txt_to_csv)
box::use(code/county/industries/map_industries_to_counties)
box::use(code/county/industries/map_dominant_industries_to_covariates)
box::use(code/db/init_db)
box::use(code/plots/gini_vs_le_gap)