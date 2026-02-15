# Compare Two Excel Files Cell by Cell

Compares two Excel files (.xlsx/.xlsm) at the cell level, identifying
differences in content based on cell position (row, column). This
function captures all cells in a worksheet, including titles, footnotes,
and annotations outside the main data table.

## Usage

``` r
compare_xlsx(file1, file2, sheet = 1, tolerance = NULL, na_equals_zero = FALSE)
```

## Arguments

- file1:

  Path to the first Excel file (.xlsx or .xlsm).

- file2:

  Path to the second Excel file (.xlsx or .xlsm).

- sheet:

  Sheet(s) to compare. Can be:

  - An integer or character scalar (compare a single sheet)

  - An integer or character vector (compare multiple sheets)

  - `NULL` (compare all sheets that exist in both files)

  Defaults to `1` (first sheet).

- tolerance:

  Numeric tolerance for value comparison. `NULL` (default) uses exact
  string comparison (original behavior). A numeric value enables
  type-aware comparison where two numeric values are considered equal if
  their absolute difference is at most `tolerance`. Character values
  that look like numbers (including comma-decimal notation like
  `"10,5"`) are automatically parsed.

- na_equals_zero:

  If `TRUE`, treat pairs where one value is `NA` and the other is `0` as
  identical. Defaults to `FALSE`.

## Value

A tibble with columns:

- sheet:

  Name of the worksheet

- row:

  Row number of the cell

- col:

  Column number of the cell

- address:

  Excel cell address (e.g., "A1", "B2")

- value1:

  Cell value in file1 (NA if cell doesn't exist)

- value2:

  Cell value in file2 (NA if cell doesn't exist)

- status:

  Type of difference: "modified", "added", or "removed"

Returns an empty tibble (with all columns) if files are identical.

## Examples

``` r
file1 <- system.file("extdata", "example1.xlsx", package = "excelcompare")
file2 <- system.file("extdata", "example2.xlsx", package = "excelcompare")

# Compare two Excel files (exact string comparison)
compare_xlsx(file1, file2)
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]

# Compare with numeric tolerance
compare_xlsx(file1, file2, tolerance = 0.05)
#> 
#> ── Excel Comparison ────────────────────────────────────────────────────────────
#> Sheet: "Sheet1" | 2 differences
#> 
#> A1: Title -> Different Title [modified]
#> A4: 2 -> 99 [modified]

# Multi-sheet files
multi1 <- system.file("extdata", "example_multi1.xlsx", package = "excelcompare")
multi2 <- system.file("extdata", "example_multi2.xlsx", package = "excelcompare")

# Compare all shared sheets
compare_xlsx(multi1, multi2, sheet = NULL)
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
