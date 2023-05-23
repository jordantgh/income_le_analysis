box::use(
    dplyr[...],
    ./cleanup_functions[...]
)

ConstraintHolder <- R6::R6Class(
    "ConstraintHolder",
    public = list(
        id = NULL,
        constraints = NULL,
        initialize = function(id) {
            self$id <- id
            self$constraints <- list()
        },
        addConstraint = function(bound, comparison, name = NULL) {
            new_cb <- Constraint$new(
                bound, comparison,
                name = name
            )
            self$constraints[[name]] <- new_cb
            invisible(self)
        }
    )
)

# constraint class without potentialCols property
Constraint <- R6::R6Class(
    "Constraint",
    public = list(
        bound = NULL,
        comparison = NULL,
        name = NULL,
        initialize = function(bound, comparison, name = NULL) {
            self$bound <- bound
            self$comparison <- comparison
            self$name <- name
        }
    )
)

CCMetaClass <- R6::R6Class(
    "CCMetaClass",
    public = list(
        colChecks = NULL,
        initialize = function() {
            self$colChecks <- list()
        },
        addColCheck = function(constraint, data, overview) {
            new_cc <- ColCheck$new(constraint, data, overview)
            self$colChecks[[constraint$name]] <- new_cc
            invisible(self)
        },
        getColCheck = function(name) {
            return(self$colChecks[[name]])
        }
    )
)


ColCheck <- R6::R6Class(
    "ColCheck",
    public = list(
        constraint = NULL,
        potentialCols = NULL,
        name = NULL,
        initialize = function(constraint, data, overview) {
            self$constraint <- constraint
            self$name <- constraint$name
            self$addPotentialCols(data, overview)
        },
        addPotentialCols = function(data, overview) {
            comparitor <- match.fun(self$constraint$comparison)

            if (self$constraint$comparison %in% c("<=", "<")) {
                get_extreme <- min
            } else if (self$constraint$comparison %in% c(">=", ">")) {
                get_extreme <- max
            } else {
                stop("Invalid comparitor. Please use one of: <=, <, >=, >")
            }

            bounded_cols <- data %>%
                select_if(\(x) comparitor(
                    get_extreme(x, na.rm = TRUE),
                    self$constraint$bound
                )) %>%
                names()
            intersected_cols <- intersect(names(overview), bounded_cols)
            self$potentialCols <- overview[intersected_cols]
        },
        getConstraint = function() {
            return(self$constraint)
        },
        getPotentialCols = function() {
            return(self$potentialCols)
        },
        createColFilter = function(pattern, filterNonMatches = FALSE) {
            return(ColFilter$new(self, pattern, filterNonMatches))
        }
    )
)

ColFilter <- R6::R6Class(
    "ColFilter",
    public = list(
        colCheck = NULL,
        pattern = NULL,
        filterNonMatches = NULL,
        initialize = function(col_check, pattern, filterNonMatches = FALSE) {
            self$colCheck <- col_check
            self$pattern <- pattern
            self$filterNonMatches <- filterNonMatches
        },
        getColCheck = function() {
            return(self$colCheck)
        }
    )
)