# excelcompare 0.0.0.9000

* Added `compare_xlsx()` for cell-by-cell comparison of Excel files.
* Added `safe_to_numeric()` with support for comma-decimal, scientific notation,
  and thousand separators.
* Multi-sheet support: `sheet` parameter accepts `NULL` (all shared sheets),
  character/integer vectors.
* Custom S3 class `excelcompare_diff` with `print()` and `summary()` methods.
* Input validation: file extension, sheet name/index, and corrupt file handling.
* Informative CLI messages in interactive sessions.
