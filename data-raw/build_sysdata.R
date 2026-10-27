# Builds R/sysdata.rda from the globorisk R package's internal data.
#
# Usage (from the package root):
#   Rscript data-raw/build_sysdata.R <path to a boyercb/globorisk checkout>
#
# Source: https://github.com/boyercb/globorisk, commit
# ea833709d3b7e7f691f666054677d0094f3b10e7 (14 October 2026), R/sysdata.rda
# (MIT licence, (c) 2021 globorisk authors; see inst/LICENSE-globorisk.md).
# Only data are read; none of the package's code is run. Values are kept at full
# precision. Only the 2017 laboratory-based and office-based models (fatal and
# non-fatal CVD) are kept; the fatal-only model and the Globorisk-LAC
# coefficients are not used.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
src <- new.env()
load(file.path(args[1], "R", "sysdata.rda"), envir = src)
stopifnot(all(vapply(mget(c("coefs", "cvdr", "rf"), src), is.data.frame, TRUE)))

cf <- as.data.frame(src$coefs)
cf <- cf[cf$lac == 0 & cf$type %in% c("lab", "office"), ]
coefs <- list(
  lab = unlist(cf[cf$type == "lab", c("main_sbpc", "main_tcc", "main__Idm_1",
                                      "main_smok", "main_sexdm", "main_sexsmok",
                                      "tvc_sbpc", "tvc_tcc", "tvc_dm",
                                      "tvc_smok")]),
  office = unlist(cf[cf$type == "office", c("main_sbpc", "main_bmi5c",
                                            "main_smokc", "main_sexsmokc",
                                            "tvc_sbpc", "tvc_smokc",
                                            "tvc_bmi5c")]))

# Fatal and non-fatal CVD rates. In the source, cvd_i is the rate for calendar
# year (baseline year + i) and age group max(baseline age group,
# trunc((age + i) / 5) - 7); each such cell has a single value, so the rates
# are stored once per country, sex, calendar year and age group.
cv <- as.data.frame(src$cvdr)
cv <- cv[cv$type == "FNF", ]
isos <- sort(unique(cv$iso))
long <- do.call(rbind, lapply(0:9, function(i) {
  d <- data.frame(iso = cv$iso, sex = cv$sex, cal = cv$year + i,
                  agej = pmax(cv$agec, trunc((cv$age + i) / 5) - 7),
                  rate = cv[[paste0("cvd_", i)]])
  d[!is.na(d$rate), ]
}))
rates <- array(NA_real_, c(length(isos), 2L, 30L, 10L),
               dimnames = list(isos, c("male", "female"), 2000:2029, 1:10))
idx <- cbind(match(long$iso, isos), long$sex + 1L, long$cal - 1999L, long$agej)
rates[idx] <- long$rate
chk <- tapply(long$rate, paste(idx[, 1], idx[, 2], idx[, 3], idx[, 4]),
              function(x) diff(range(x)))
stopifnot(max(chk) == 0)

# Mean risk factor levels by country, sex and 5-year age group (agec 1 = 40-44).
# mean_sbp is in units of 10 mmHg and mean_bmi in units of 5 kg/m2, as in the
# source.
rf <- as.data.frame(src$rf)
rf <- rf[rf$iso %in% isos, ]
means <- array(NA_real_, c(length(isos), 2L, 10L, 5L),
               dimnames = list(isos, c("male", "female"), 1:10,
                               c("sbp", "tc", "dm", "smk", "bmi")))
for (v in dimnames(means)[[4]]) {
  means[cbind(match(rf$iso, isos), rf$sex + 1L, rf$agec, match(v, dimnames(means)[[4]]))] <-
    rf[[paste0("mean_", v)]]
}

.gl_data <- list(coefs = coefs, rates = rates, means = means,
                 source = "boyercb/globorisk ea833709d3b7e7f691f666054677d0094f3b10e7")
save(.gl_data, file = "R/sysdata.rda", compress = "xz")
cat("R/sysdata.rda:", file.size("R/sysdata.rda"), "bytes;", length(isos),
    "countries\n")
