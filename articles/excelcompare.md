# Getting Started with excelcompare

## Overview

**excelcompare** compares Excel files (.xlsx/.xlsm) at the cell level.
Unlike tools that only compare tabular data, excelcompare captures
*every cell* in a worksheet — including titles, footnotes, and
annotations outside the main data table.

``` r
library(excelcompare)
```

## Basic Comparison

The main function is
[`compare_xlsx()`](https://schmidtpaul.github.io/excelcompare/reference/compare_xlsx.md).
It takes two file paths and returns a tibble of cell-level differences.

``` r
file1 <- system.file("extdata", "example1.xlsx", package = "excelcompare")
file2 <- system.file("extdata", "example2.xlsx", package = "excelcompare")

diffs <- compare_xlsx(file1, file2)
diffs
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]
```

Each row represents one cell that differs between the two files:

- **sheet**: the worksheet name
- **address**: the Excel cell address (e.g., “A1”, “B3”)
- **value1** / **value2**: the cell content in file 1 and file 2
- **status**: `"modified"` (changed), `"added"` (only in file 2), or
  `"removed"` (only in file 1)

## Numeric Tolerance

By default, values are compared as exact strings. If you expect small
numeric differences (e.g., from rounding), use the `tolerance`
parameter:

``` r
# Treat differences up to 0.05 as equal
diffs_tol <- compare_xlsx(file1, file2, tolerance = 0.05)
diffs_tol
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]
```

Tolerance-aware comparison automatically handles:

- Numeric cells stored as numbers
- Text cells that look like numbers (including comma-decimal like
  `"10,5"`)
- Scientific notation (e.g., `"1e-5"`)

## NA-equals-Zero

In some workflows, empty cells and zero-valued cells are treated as
equivalent. Enable this with `na_equals_zero = TRUE`:

``` r
compare_xlsx(file1, file2, na_equals_zero = TRUE)
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]
```

## Multi-Sheet Comparison

Use the `sheet` parameter to control which sheets are compared:

``` r
multi1 <- system.file("extdata", "example_multi1.xlsx", package = "excelcompare")
multi2 <- system.file("extdata", "example_multi2.xlsx", package = "excelcompare")

# Compare all shared sheets (sheet = NULL)
all_diffs <- compare_xlsx(multi1, multi2, sheet = NULL)
all_diffs
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Data" | 2 differences
#> 
#> A3: 2 -> 99 [modified]
#> B4: z -> w [modified]
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Summary" | 1 difference
#> 
#> A2: 6 -> 7 [modified]
```

You can also specify sheets by name or index:

``` r
# By name
compare_xlsx(multi1, multi2, sheet = "Data")
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Data" | 2 differences
#> 
#> A3: 2 -> 99 [modified]
#> B4: z -> w [modified]

# Multiple sheets
compare_xlsx(multi1, multi2, sheet = c("Data", "Summary"))
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Data" | 2 differences
#> 
#> A3: 2 -> 99 [modified]
#> B4: z -> w [modified]
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Summary" | 1 difference
#> 
#> A2: 6 -> 7 [modified]
```

## Summary View

For a quick overview, use
[`summary()`](https://rdrr.io/r/base/summary.html):

``` r
summary(all_diffs)
#> 
#> ── Excel Comparison Summary ────────────────────────────────────────────────────
#> 3 differences across 2 sheets
#> 
#> Sheet "Data": 2 modified
#> Sheet "Summary": 1 modified
```

## Utility: safe_to_numeric()

The package also exports
[`safe_to_numeric()`](https://schmidtpaul.github.io/excelcompare/reference/safe_to_numeric.md),
which converts character values to numeric while handling multiple
decimal separators:

``` r
safe_to_numeric("10.5")
#> [1] 10.5
safe_to_numeric("10,5")
#> [1] 10.5
safe_to_numeric("1.234,56")
#> [1] 1234.56
safe_to_numeric("1e-5")
#> [1] 1e-05
safe_to_numeric(c("10.5", "10,5", "text"))
#> [1] 10.5 10.5   NA
```
