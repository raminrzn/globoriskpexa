.gl_vars <- c("country", "year", "sex", "age", "sbp", "smoker", "total_chol",
              "diabetes", "bmi", "version", "chol_units")
.gl_alias <- c(iso = "country", iso3 = "country", baseline_year = "year",
               smk = "smoker", smoking = "smoker", tc = "total_chol",
               cholesterol = "total_chol", dm = "diabetes")

#' Globorisk (ModelsCloud entry point)
#' @param model_input Named list of inputs; see [globorisk()].
#' @param ... The same fields as named arguments.
#' @return See [globorisk()].
#' @export
model_run <- function(model_input = NULL, ...) {
  args <- .gl_normalize(model_input, list(...), .gl_vars, .gl_alias)
  if (is.null(args) || length(args) == 0) args <- get_default_input()
  missing <- setdiff(c("country", "year", "sex", "age", "sbp", "smoker"),
                     names(args))
  if (length(missing) > 0) {
    stop("Missing required variable(s): ", paste(missing, collapse = ", "), ".",
         call. = FALSE)
  }
  do.call(globorisk, args)
}

#' Example Globorisk inputs
#' @param n Optional number of rows.
#' @param ... Ignored.
#' @export
get_sample_input <- function(n = NULL, ...) {
  df <- data.frame(country = c("CHN", "USA"), year = 2015, sex = "male",
                   age = 65, sbp = 160, smoker = "no", total_chol = 6,
                   diabetes = "yes", stringsAsFactors = FALSE)
  if (!is.null(n)) df <- utils::head(df, n)
  df
}

#' Default Globorisk input (the example in Ueda et al. 2017, China)
#' @param ... Ignored.
#' @export
get_default_input <- function(...) {
  list(country = "CHN", year = 2015, sex = "male", age = 65, sbp = 160,
       smoker = "no", total_chol = 6, diabetes = "yes", version = "lab")
}
