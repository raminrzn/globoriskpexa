# globoriskpexa

Ten-year risk of fatal and non-fatal cardiovascular disease (CVD) from the
2017 **Globorisk** laboratory-based and office-based risk scores, recalibrated
to the person's country and baseline year.

Ueda P, et al. Laboratory-based and office-based risk scores and charts to
predict 10-year risk of cardiovascular disease in 182 countries: a pooled
analysis of prospective cohorts and health surveys. *Lancet Diabetes
Endocrinol.* 2017;5:196–213.
[doi:10.1016/S2213-8587(17)30015-3](https://doi.org/10.1016/S2213-8587(17)30015-3)

Method: Hajifathalian K, et al. *Lancet Diabetes Endocrinol.*
2015;3:339–355. [doi:10.1016/S2213-8587(15)00081-9](https://doi.org/10.1016/S2213-8587(15)00081-9)

## Version

- **Equations:** the 2017 laboratory-based (age, sex, SBP, total
  cholesterol, diabetes, smoking) and office-based (diabetes and cholesterol
  replaced by BMI) models.
- **Calibration data:** country CVD rates (2000–2029) and mean risk factor
  levels from the authors' R package
  [boyercb/globorisk](https://github.com/boyercb/globorisk), pinned at commit
  `ea83370` (14 October 2026), MIT licence (`data-raw/build_sysdata.R`). These
  are not the same data as those behind the 2017 paper's charts (see
  Validation).
- **Not included:** the 2015 fatal-only model and the Globorisk-LAC update
  (2022), which are separate models.

The calculation follows the authors' package, which was reimplemented here
from its source rather than called.
1. Risk factors are centred on the country's mean level for the person's sex
   and 5-year age group.
2. Effects decline with age.
3. Each of the 10 years has its own hazard: the country's CVD rate for that
   calendar year and age group, times the person's hazard ratio.

## Inputs

| Field | Meaning |
|---|---|
| `country` | ISO alpha-3 code, 182 countries (South Sudan has no risk factor data in the source) |
| `year` | baseline year, 2000–2020 |
| `sex` | male / female |
| `age` | 40–74 years (whole years are used); the paper limits prediction to 40–74 |
| `sbp` | systolic blood pressure, mmHg (70–270) |
| `smoker` | current smoker, yes/no |
| `total_chol` | total cholesterol, mmol/L (or mg/dL with `chol_units`); laboratory model |
| `diabetes` | yes/no; laboratory model |
| `bmi` | kg/m² (10–80); office model |
| `version` | `lab` or `office`; if omitted, `lab` when cholesterol and diabetes are given |

Returns `risk_10y` (0–1), with the version, country and year used.

## Validation

- **Coefficients:** all 17 lab and office coefficients equal Table 1 of
  Ueda et al. 2017 to its 4 printed decimals. This check is independent of
  the package.
- **Authors' package outputs:** the three laboratory-model results printed
  in the authors' package documentation (0.3559493, 0.6000554, 0.2284217) are
  reproduced exactly. This checks fidelity to the authors' code. It is not an
  independent clinical validation.
- **Paper's worked example:** close but not exact. The example is a
  non-smoking 65-year-old man with diabetes, SBP 160 mmHg and total
  cholesterol 6 mmol/L, plus the same profile for a smoker. At baseline year
  2015:

  | | Paper | This package |
  |---|---|---|
  | Japan, non-smoker | 21% | 19.5% |
  | USA, non-smoker | 21% | 20.9% |
  | China, non-smoker | 53% | 48.4% |
  | Japan, smoker | 26% | 25.8% |
  | China, smoker | 62% | 59.1% |

  No baseline year reproduces all five. The package's calibration data
  (rates projected to 2029) are a later update than those used for the 2017
  charts (projected to 2024).

## Use

```r
remotes::install_git("https://github.com/raminrzn/globoriskpexa", ref = "main")
globoriskpexa::globorisk(country = "CHN", year = 2015, sex = "male", age = 65,
                         sbp = 160, smoker = "no", total_chol = 6,
                         diabetes = "yes")
```

For research use. Not a medical device.

## Licence

GPL-3. Coefficients and calibration data are from the globorisk R package, MIT
licence, © 2021 globorisk authors (`inst/LICENSE-globorisk.md`).
