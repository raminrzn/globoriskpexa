test_that("coefficients equal Table 1 of Ueda et al. 2017 to its 4 decimals", {
  b <- globoriskpexa:::.gl_data$coefs
  lab <- c(main_sbpc = 0.3070, main_tcc = 0.6149, main__Idm_1 = 1.4753,
           main_smok = 1.8467, main_sexdm = 0.4050, main_sexsmok = 0.3254,
           tvc_sbpc = -0.0022, tvc_tcc = -0.0069, tvc_dm = -0.0132,
           tvc_smok = -0.0221)
  office <- c(main_sbpc = 0.3037, main_bmi5c = 0.3245, main_smokc = 1.7951,
              main_sexsmokc = 0.3528, tvc_sbpc = -0.0021, tvc_smokc = -0.0215,
              tvc_bmi5c = -0.0030)
  expect_true(all(abs(b$lab[names(lab)] - lab) <= 0.00005 + 1e-12))
  expect_true(all(abs(b$office[names(office)] - office) <= 0.00005 + 1e-12))
})

test_that("results equal those printed by the authors' globorisk package", {
  # globorisk 1.0.2 reference page (pkgdown), laboratory model:
  # 0.3559493 0.6000554 0.2284217
  r <- c(globorisk("AFG", 2000, "female", 52, 140, "no", 4.5, "yes")$risk_10y,
         globorisk("AFG", 2000, "male", 60, 160, "yes", 5, "yes")$risk_10y,
         globorisk("USA", 2020, "male", 65, 170, "yes", 5, "yes")$risk_10y)
  expect_equal(round(r, 7), c(0.3559493, 0.6000554, 0.2284217))
})

test_that("the worked example in Ueda et al. 2017 is close but not exact", {
  # Paper: 21% (Japan, USA) and 53% (China) for a non-smoking 65-year-old man
  # with diabetes, SBP 160, total cholesterol 6 mmol/L; 26% and 62% for a
  # smoker in Japan and China. The calibration data here are the authors'
  # later package data, not those behind the 2017 charts.
  r <- function(iso, smk) globorisk(iso, 2015, "male", 65, 160, smk, 6, "yes")$risk_10y
  expect_equal(round(100 * c(r("JPN", "no"), r("USA", "no"), r("CHN", "no"),
                             r("JPN", "yes"), r("CHN", "yes")), 1),
               c(19.5, 20.9, 48.4, 25.8, 59.1))
})

test_that("inputs are checked and versions chosen", {
  x <- get_default_input()
  expect_equal(model_run(x)$version, "laboratory-based (2017)")
  o <- list(country = "zaf", year = 2020, sex = "female", age = 52, sbp = 140,
            smoker = "no", bmi = 28)
  ro <- model_run(o)
  expect_equal(ro$version, "office-based (2017)")
  expect_equal(ro$country, "ZAF")
  expect_true(ro$risk_10y > 0 && ro$risk_10y < 1)
  mg <- x
  mg$total_chol <- 6 * 38.67
  mg$chol_units <- "mg/dL"
  expect_equal(model_run(mg)$risk_10y, model_run(x)$risk_10y)
  expect_error(model_run(modifyList(x, list(country = "SSD"))), "country")
  expect_error(model_run(modifyList(x, list(age = 75))), "age")
  expect_error(model_run(modifyList(x, list(year = 2021))), "year")
  expect_error(model_run(modifyList(x, list(total_chol = NULL))), "laboratory")
  expect_error(model_run(modifyList(o, list(version = "office", bmi = NULL))), "bmi")
  expect_equal(length(globoriskpexa:::.gl_countries()), 182L)
})

test_that("gateway returns full precision and drops JSON nulls", {
  x <- get_default_input()
  js <- gateway(model_input = c(x, list(bmi = NULL)), execution_id = "z")
  expect_equal(jsonlite::fromJSON(js)$risk_10y, model_run(x)$risk_10y,
               tolerance = 1e-12)
})
