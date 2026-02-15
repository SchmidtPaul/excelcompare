
<!-- README.md is generated from README.Rmd. Please edit that file -->

# excelcompare

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/SchmidtPaul/excelcompare/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SchmidtPaul/excelcompare/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Compare Excel files (.xlsx) cell by cell. Unlike standard table
comparison tools, excelcompare captures **every cell** in a worksheet -
including titles, footnotes, and annotations that live outside the main
data table.

## Installation

You can install the development version of excelcompare from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("SchmidtPaul/excelcompare")
```

## Example

``` r
library(excelcompare)

# Paths to example Excel files shipped with the package
path1 <- system.file("extdata", "example1.xlsx", package = "excelcompare")
path2 <- system.file("extdata", "example2.xlsx", package = "excelcompare")

# Compare the two files
diff <- compare_xlsx(path1, path2)

# The result is a tibble with one row per difference
diff
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]
```

``` r
# The print method shows waldo-inspired diffs
print(diff)
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]
```

## Features

- **Cell-level comparison** - Detects differences in any cell, not just
  tabular data
- **Numeric tolerance** - `tolerance` parameter for floating-point
  comparison
- **NA-equals-zero** - `na_equals_zero` parameter to treat empty cells
  and zeros as equal
- **Multi-sheet support** - Compare specific or all shared sheets
  (`sheet` parameter)
- **Clean diff output** - S3 print/summary methods with waldo-inspired
  formatting
- **`safe_to_numeric()`** - Exported utility for robust numeric
  conversion (handles European formats, thousand separators)

## Learn more

- [Getting Started
  vignette](https://schmidtpaul.github.io/excelcompare/articles/excelcompare.html)
- [Function
  reference](https://schmidtpaul.github.io/excelcompare/reference/)

Built on [{tidyxl}](https://nacnudus.github.io/tidyxl/) for
comprehensive Excel cell reading. Only supports modern Excel formats
(.xlsx, .xlsm).
