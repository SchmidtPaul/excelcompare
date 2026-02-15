# CLAUDE.md - Project Guide for AI Assistants

## Project Overview

**excelcompare** is an R package for comparing Excel files (.xlsx/.xlsm) at the cell level.

### Key Features
- **Cell-by-cell comparison**: Compare ALL cells in a worksheet, not just tabular data
- **Full coverage**: Includes titles, footnotes, annotations above/below tables
- **Multi-sheet support**: Compare single, multiple, or all shared sheets
- **Numeric tolerance**: Type-aware comparison with configurable tolerance
- **Custom output**: S3 class `excelcompare_diff` with waldo-inspired print method
- **Format comparison** (roadmap): Font, colors, borders, etc.
- **Side-by-side helper** (roadmap): Open two Excel files in Excel

### Technical Stack
- **Backend**: `tidyxl` - reads every cell with position, content, and formatting
- **Output style**: Inspired by `waldo` for clean diff output
- **Scope**: Only .xlsx/.xlsm files (no legacy .xls support)

## Development Guidelines

### Code Style
- Follow tidyverse style guide
- Use roxygen2 with Markdown enabled (`#' @param x Description`)
- Pipe operator: Use base R `|>` (not magrittr `%>%`)
- All functions should have complete roxygen2 documentation including `@examples`

### Before Making Changes
**Always read all files in `R/` before modifying any code** to understand:
- Existing function signatures
- Internal helper functions
- Package conventions

### Package Structure
```
R/                     # R source files
  compare_xlsx.R       # Main function + validation/IO helpers
  compare_values.R     # values_are_equal() comparison logic
  safe_to_numeric.R    # Exported numeric conversion utility
  print.R              # S3 print/summary methods
  excelcompare-package.R  # Package-level imports
tests/testthat/        # Unit tests (111 tests)
  fixtures/            # Test Excel files
  _snaps/              # Snapshot test outputs
inst/extdata/          # Example data for runnable examples
vignettes/             # Getting Started vignette
man/                   # Generated documentation (do not edit)
```

### Running Tests
```r
devtools::test()
devtools::check()
```

### Key Dependencies
- `tidyxl`: Excel cell reading
- `dplyr`: Data manipulation
- `cli`: User-friendly console output
- `rlang`: `.data` pronoun, `is_interactive()`
- `readr`: Locale-aware number parsing (in `safe_to_numeric()`)
