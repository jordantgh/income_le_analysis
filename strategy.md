# Going through all the files and figuring out what's needed

1. Add region data to the crosswalk csv.

2. Table 1 (national-wide LE by income percentile) is derivative of table 2 (which is by year); could remove.

3. Tables 3 and 4 (State-level LE by gender by income, and trend (tab 4)) appears to be derived from Table 5. We could also use table 9 (CZ-level by-year LE by gender by income) for a lower level of granularity, but there is no by year county data.

4. Table 9 can be used to derived tables 6 and 8, but table 7 uses ventiles. I haven't found ventile by year table yet.

5. Table 10 contains CZ-level covariates.

6. Table 11 contains county level LE by gender by income quartile; 12 contains county-level covariates

Note: Race adjustment is performed by normalising the racial composition of each geographical unit to that of the overall national average