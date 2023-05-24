box::use(
  dplyr[...],
  purrr[keep, map, pmap_dfc],
  glue[g = glue],
  utils[head, tail],
  stats[sd, lm],
  mice[md.pattern, mice, complete],
  tibble[as_tibble],
  . / classes[...]
)

# Function for selecting and cleaning the joined table
StripCols <- function(original_df, ...) {
  list_of_vars <- list(...)
  all_vars <- do.call(c, list_of_vars)
  le_covars <- original_df %>%
    select(!all_of(all_vars))
  return(le_covars)
}


# Function for checking ranges of values
CheckRanges <- function(le_covars) {
  overview <- map(
    le_covars,
    \(col)  {
      g("\nMAX: {max(col, na.rm = TRUE)} \nMIN: {min(col, na.rm = TRUE)}")
    }
  )
  return(overview)
}

OutliersToNA <- function(df, filter) {
  constraint <- filter$getColCheck()$constraint
  condition <- function(x) {
    comparitor <- match.fun(constraint$comparison)(x, constraint$bound)
  }

  if (filter$filterNonMatches) {
    df <- df %>%
      mutate(across(
        !matches(filter$pattern),
        \(x) replace(x, condition(x), NA)
      ))
  } else {
    df <- df %>%
      mutate(across(
        matches(filter$pattern),
        \(x) replace(x, condition(x), NA)
      ))
  }

  return(df)
}



# Function for converting imputed values back to the original scale
unscale <- function(imputed_data, original_means, original_sds) {
  final_imputed <- pmap_dfc(
    list(imputed_data, original_sds, original_means),
    function(z_data, sd, mean) {
      z_data * sd + mean
    }
  )
  return(final_imputed)
}

get_filter_containers <- function(df, cb_meta) {
  overview <- CheckRanges(df)

  ccm <- CCMetaClass$new()

  for (cb in cb_meta$constraints) {
    ccm$addColCheck(cb, df, overview)
  }

  return(ccm)
}

process_imputation <- function(df, filters, original_df, non_imputed) {
  for (filter in filters) {
    df <- OutliersToNA(df, filter)
  }

  df <- df %>%
    select_if(\(x) {
      sum(is.na(x)) / nrow(df) < 0.1
    })

  original_means <- df %>%
    map(\(col) mean(col, na.rm = TRUE))
  original_sds <- df %>%
    map(\(col) sd(col, na.rm = TRUE))

  df_z <- df %>%
    mutate(across(everything(), \(col) as.numeric(scale(col))))
  imputed_z <- mice(df_z, m = 1, maxit = 20, printFlag = FALSE) %>%
    complete(action = "long") %>%
    select(-c(1, 2))

  final_imputed <- unscale(imputed_z, original_means, original_sds)
  final_imputed <- original_df %>%
    select(all_of(non_imputed)) %>%
    bind_cols(final_imputed)

  return(final_imputed)
}
