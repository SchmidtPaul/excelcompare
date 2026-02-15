# Convert values to numeric handling multiple decimal separators

Attempts to convert values to numeric. If the input is already numeric,
returns it as-is. Character strings are parsed with support for:

- Dot-decimal (`"10.5"`) and comma-decimal (`"10,5"`) notation

- Scientific notation (`"1e-5"`, `"2.5E+10"`)

- Thousand separators when both dot and comma are present (`"1.234,56"`
  European or `"1,234.56"` US)

## Usage

``` r
safe_to_numeric(val)
```

## Arguments

- val:

  A numeric, character, or other vector to convert to numeric.

## Value

Numeric vector of the same length, with `NA` for values that cannot be
parsed.

## Details

The function is vectorized: when given a character vector, each element
is parsed independently.

## Examples

``` r
safe_to_numeric(10.5)
#> [1] 10.5
safe_to_numeric("10.5")
#> [1] 10.5
safe_to_numeric("10,5")
#> [1] 10.5
safe_to_numeric("-3.14")
#> [1] -3.14
safe_to_numeric("1e-5")
#> [1] 1e-05
safe_to_numeric("1.234,56")
#> [1] 1234.56
safe_to_numeric(c("10.5", "10,5", "text", "1e-3"))
#> [1] 10.500 10.500     NA  0.001
```
