# CLAUDE.md - Project Guide for AI Assistants

## Project Overview

**excelcompare** is an R package for comparing Excel files (.xlsx/.xlsm) at the cell level.

### Key Features (Planned)
- **Cell-by-cell comparison**: Compare ALL cells in a worksheet, not just tabular data
- **Full coverage**: Includes titles, footnotes, annotations above/below tables
- **Format comparison** (future): Font, colors, borders, etc
- **Helper functions**: Open two Excel files side by side for visual comparison

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
R/               # R source files
tests/testthat/  # Unit tests
man/             # Generated documentation (do not edit)
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
