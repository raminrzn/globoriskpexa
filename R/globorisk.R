#' Globorisk: 10-year risk of fatal and non-fatal CVD
#'
#' The 2017 Globorisk laboratory-based or office-based risk score, recalibrated
#' to the country and baseline year. Follows the calculation in the authors'
#' globorisk R package (commit ea83370): each of the 10 years has its own
#' hazard, equal to the country's CVD rate for that calendar year and age group
#' times the person's hazard ratio. Risk factors are centred on the country's
#' mean levels for the person's sex and 5-year age group at baseline, and
#' their effects decline with age.
#'
#' @param country ISO 3166-1 alpha-3 country code (182 countries).
#' @param year Baseline year, 2000 to 2020.
#' @param sex `"male"` or `"female"`.
#' @param age Age in years, 40 to 74 (whole years are used).
#' @param sbp Systolic blood pressure, mmHg.
#' @param smoker Current smoker (yes/no).
#' @param total_chol Total cholesterol (laboratory model).
#' @param diabetes Diabetes (yes/no; laboratory model).
#' @param bmi Body mass index, kg/m2 (office model).
#' @param version `"lab"` or `"office"`. If omitted, `"lab"` when total
#'   cholesterol and diabetes are given, otherwise `"office"`.
#' @param chol_units `"mmol/L"` (default) or `"mg/dL"`.
#' @return A list with `risk_10y` and the version, country and year used.
#' @export
globorisk <- function(country, year, sex, age, sbp, smoker, total_chol = NULL,
                      diabetes = NULL, bmi = NULL, version = NULL,
                      chol_units = c("mmol/L", "mg/dL")) {
  D <- .gl_data
  if (is.null(version)) {
    version <- if (!is.null(total_chol) && !is.null(diabetes)) "lab" else "office"
  }
  version <- match.arg(tolower(version), c("lab", "office"))
  chol_units <- match.arg(chol_units)
  iso <- toupper(trimws(as.character(country)))
  if (!iso %in% .gl_countries()) {
    stop("`country` must be an ISO alpha-3 code covered by Globorisk ",
         "(182 countries); \"", country, "\" is not.", call. = FALSE)
  }
  year <- .gl_num(year, "year", 2000, 2020)
  if (year != round(year)) stop("`year` must be a whole year.", call. = FALSE)
  s <- .gl_sex(sex)
  age <- trunc(.gl_num(age, "age", 40, 74))
  sbp <- .gl_num(sbp, "sbp", 70, 270)
  smk <- .gl_yesno(smoker, "smoker")

  agec <- trunc(age / 5) - 7
  m <- D$means[iso, s + 1L, agec, ]
  t <- 0:9
  agej <- pmax(agec, trunc((age + t) / 5) - 7)
  rate <- D$rates[cbind(match(iso, dimnames(D$rates)[[1]]), s + 1L,
                        year + t - 1999L, agej)]
  sbp_c <- sbp / 10 - m[["sbp"]]
  smk_c <- smk - m[["smk"]]

  if (version == "lab") {
    if (is.null(total_chol) || is.null(diabetes)) {
      stop("The laboratory model needs `total_chol` and `diabetes`.",
           call. = FALSE)
    }
    tc <- .gl_num(total_chol, "total_chol",
                  if (chol_units == "mg/dL") 1.75 * 38.67 else 1.75,
                  if (chol_units == "mg/dL") 20 * 38.67 else 20)
    if (chol_units == "mg/dL") tc <- tc / 38.67
    dm <- .gl_yesno(diabetes, "diabetes")
    b <- D$coefs$lab
    tc_c <- tc - m[["tc"]]
    dm_c <- dm - m[["dm"]]
    lp <- sbp_c * b[["main_sbpc"]] + tc_c * b[["main_tcc"]] +
      dm_c * b[["main__Idm_1"]] + smk_c * b[["main_smok"]] +
      s * dm_c * b[["main_sexdm"]] + s * smk_c * b[["main_sexsmok"]] +
      (age + t) * (sbp_c * b[["tvc_sbpc"]] + tc_c * b[["tvc_tcc"]] +
                     dm_c * b[["tvc_dm"]] + smk_c * b[["tvc_smok"]])
  } else {
    if (is.null(bmi)) stop("The office model needs `bmi`.", call. = FALSE)
    bmi_c <- .gl_num(bmi, "bmi", 10, 80) / 5 - m[["bmi"]]
    b <- D$coefs$office
    lp <- sbp_c * b[["main_sbpc"]] + bmi_c * b[["main_bmi5c"]] +
      smk_c * b[["main_smokc"]] + s * smk_c * b[["main_sexsmokc"]] +
      (age + t) * (sbp_c * b[["tvc_sbpc"]] + smk_c * b[["tvc_smokc"]] +
                     bmi_c * b[["tvc_bmi5c"]])
  }
  risk <- 1 - prod(exp(-exp(lp) * rate))
  list(risk_10y = risk,
       version = if (version == "lab") "laboratory-based (2017)" else "office-based (2017)",
       country = iso, year = as.integer(year))
}

# Countries with both CVD rates and mean risk factor levels. South Sudan has
# rates but no risk factor means in the source data, so it is excluded.
.gl_countries <- function() {
  m <- .gl_data$means
  dimnames(m)[[1]][!apply(is.na(m[, , 1:7, ]), 1, any)]
}

.gl_sex <- function(x) {
  key <- tolower(trimws(as.character(x)))
  if (key %in% c("male", "m", "man")) return(0L)
  if (key %in% c("female", "f", "woman")) return(1L)
  stop('`sex` must be "male" or "female".', call. = FALSE)
}
