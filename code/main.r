# this script will orchestrate all the other scripts
# and set up the environment

box::use(
    code/region/assign_region,
    code/county/add_industries/convert_naics_codes_txt_to_csv,
    code/county/add_industries/map_industries_to_counties,
    code/county/add_industries/map_dominant_industries_to_covariates,
    code/db/init_db, code/county/process_tables/county_covars_cleanup
)
