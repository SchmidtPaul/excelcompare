#' Compare Two Excel Files Cell by Cell
#'
#' Compares two Excel files (.xlsx/.xlsm) at the cell level, identifying
#' differences in content based on cell position (row, column). This function
#' captures all cells in a worksheet, including titles, footnotes, and
#' annotations outside the main data table.
#'
#' @param file1 Path to the first Excel file (.xlsx or .xlsm).
#' @param file2 Path to the second Excel file (.xlsx or .xlsm).
#' @param sheet Sheet(s) to compare. Can be:
#'   - An integer or character scalar (compare a single sheet)
#'   - An integer or character vector (compare multiple sheets)
#'   - `NULL` (compare all sheets that exist in both files)
#'
#'   Defaults to `1` (first sheet).
#' @param tolerance Numeric tolerance for value comparison. `NULL` (default)
#'   uses exact string comparison (original behavior). A numeric value enables
#'   type-aware comparison where two numeric values are considered equal if
#'   their absolute difference is at most `tolerance`. Character values that
#'   look like numbers (including comma-decimal notation like `"10,5"`) are
#'   automatically parsed.
#' @param na_equals_zero If `TRUE`, treat pairs where one value is `NA` and
#'   the other is `0` as identical. Defaults to `FALSE`.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{sheet}{Name of the worksheet}
#'     \item{row}{Row number of the cell}
#'     \item{col}{Column number of the cell}
#'     \item{address}{Excel cell address (e.g., "A1", "B2")}
#'     \item{value1}{Cell value in file1 (NA if cell doesn't exist)}
#'     \item{value2}{Cell value in file2 (NA if cell doesn't exist)}
#'     \item{status}{Type of difference: "modified", "added", or "removed"}
#'   }
#'   Returns an empty tibble (with all columns) if files are identical.
#'
#' @export
#'
#' @examples
#' file1 <- system.file("extdata", "example1.xlsx", package = "excelcompare")
#' file2 <- system.file("extdata", "example2.xlsx", package = "excelcompare")
#'
#' # Compare two Excel files (exact string comparison)
#' compare_xlsx(file1, file2)
#'
#' # Compare with numeric tolerance
#' compare_xlsx(file1, file2, tolerance = 0.05)
#'
#' # Multi-sheet files
#' multi1 <- system.file("extdata", "example_multi1.xlsx", package = "excelcompare")
#' multi2 <- system.file("extdata", "example_multi2.xlsx", package = "excelcompare")
#'
#' # Compare all shared sheets
#' compare_xlsx(multi1, multi2, sheet = NULL)
compare_xlsx <- function(file1, file2, sheet = 1,
                         tolerance = NULL, na_equals_zero = FALSE) {
  # Validate inputs
  validate_file_exists(file1)
  validate_file_exists(file2)
  validate_file_extension(file1)
  validate_file_extension(file2)
  if (!is.null(tolerance)) {
    if (!is.numeric(tolerance) || length(tolerance) != 1 || tolerance < 0) {
      cli::cli_abort(
        "{.arg tolerance} must be a single non-negative number or {.code NULL}."
      )
    }
  }
  if (!is.logical(na_equals_zero) || length(na_equals_zero) != 1) {
    cli::cli_abort("{.arg na_equals_zero} must be {.code TRUE} or {.code FALSE}.")
  }

  # Read available sheet names
  sheets1 <- read_sheet_names(file1)
  sheets2 <- read_sheet_names(file2)

  # Resolve which sheets to compare
  sheet_names <- resolve_sheets(sheet, sheets1, sheets2, file1, file2)

  # Compare each sheet
  results <- lapply(sheet_names, function(sn) {
    compare_single_sheet(
      file1, file2,
      sheet_name = sn,
      tolerance = tolerance,
      na_equals_zero = na_equals_zero
    )
  })

  differences <- dplyr::bind_rows(results)
  class(differences) <- c("excelcompare_diff", class(differences))

  if (rlang::is_interactive()) {
    emit_diff_summary(differences)
  }

  differences
}


# --- Core comparison logic ----------------------------------------------------

#' Compare a single sheet between two files
#' @noRd
compare_single_sheet <- function(file1, file2, sheet_name,
                                 tolerance, na_equals_zero) {
  if (rlang::is_interactive()) {
    cli::cli_inform("Comparing sheet {.val {sheet_name}}")
  }

  cells1 <- read_cells(file1, sheet_name)
  cells2 <- read_cells(file2, sheet_name)

  cells1 <- extract_cell_values(cells1)
  cells2 <- extract_cell_values(cells2)

  if (rlang::is_interactive()) {
    cli::cli_inform(
      "File 1: {nrow(cells1)} cell{?s} | File 2: {nrow(cells2)} cell{?s}"
    )
  }

  comparison <- dplyr::full_join(
    cells1, cells2,
    by = c("row", "col", "address"),
    suffix = c("1", "2")
  )

  comparison |>
    dplyr::filter(
      !values_are_equal(
        .data$value1, .data$value2,
        .data$value_num1, .data$value_num2,
        tolerance = tolerance,
        na_equals_zero = na_equals_zero
      )
    ) |>
    dplyr::mutate(
      sheet = sheet_name,
      status = dplyr::case_when(
        is.na(.data$value1) ~ "added",
        is.na(.data$value2) ~ "removed",
        TRUE ~ "modified"
      )
    ) |>
    dplyr::select("sheet", "row", "col", "address",
                   "value1", "value2", "status") |>
    dplyr::arrange(.data$row, .data$col)
}


#' Extract Cell Values into a Single Column
#'
#' Internal helper that coalesces tidyxl's multiple value columns
#' (character, numeric, logical, date) into a single character representation.
#'
#' @param cells A tibble from [tidyxl::xlsx_cells()].
#' @return A tibble with columns: row, col, address, value, value_num.
#' @noRd
extract_cell_values <- function(cells) {
  cells |>
    dplyr::mutate(
      value = dplyr::case_when(
        !is.na(.data$character) ~ .data$character,
        !is.na(.data$numeric) ~ as.character(.data$numeric),
        !is.na(.data$logical) ~ as.character(.data$logical),
        !is.na(.data$date) ~ as.character(.data$date),
        .data$is_blank ~ NA_character_,
        TRUE ~ NA_character_
      ),
      value_num = .data$numeric
    ) |>
    dplyr::select("row", "col", "address", "value", "value_num")
}


# --- Input validation helpers ------------------------------------------------

#' @noRd
validate_file_exists <- function(path) {
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }
}

#' @noRd
validate_file_extension <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (!ext %in% c("xlsx", "xlsm")) {
    cli::cli_abort(c(
      "Unsupported file format: {.file {path}}",
      "i" = "Only {.val .xlsx} and {.val .xlsm} files are supported."
    ))
  }
}

#' @noRd
validate_sheet <- function(sheet, available, file_path) {
  if (is.character(sheet)) {
    missing <- setdiff(sheet, available)
    if (length(missing) > 0) {
      cli::cli_abort(c(
        "Sheet {.val {missing}} not found in {.file {file_path}}.",
        "i" = "Available sheets: {.val {available}}"
      ))
    }
  } else if (is.numeric(sheet)) {
    oob <- sheet[sheet < 1 | sheet > length(available)]
    if (length(oob) > 0) {
      cli::cli_abort(c(
        "Sheet index {.val {oob}} out of range for {.file {file_path}}.",
        "i" = "File has {length(available)} sheet{?s}: {.val {available}}"
      ))
    }
  }
}

#' Resolve sheet parameter to a character vector of sheet names
#' @noRd
resolve_sheets <- function(sheet, sheets1, sheets2, file1, file2) {
  if (is.null(sheet)) {
    # NULL → compare all shared sheets
    shared <- intersect(sheets1, sheets2)
    if (length(shared) == 0L) {
      cli::cli_abort(c(
        "No shared sheets between the two files.",
        "i" = "Sheets in {.file {file1}}: {.val {sheets1}}",
        "i" = "Sheets in {.file {file2}}: {.val {sheets2}}"
      ))
    }
    only1 <- setdiff(sheets1, sheets2)
    only2 <- setdiff(sheets2, sheets1)
    if (rlang::is_interactive() && (length(only1) > 0 || length(only2) > 0)) {
      if (length(only1) > 0) {
        cli::cli_inform("Sheet{?s} only in {.file {file1}}: {.val {only1}}")
      }
      if (length(only2) > 0) {
        cli::cli_inform("Sheet{?s} only in {.file {file2}}: {.val {only2}}")
      }
    }
    return(shared)
  }

  if (!is.character(sheet) && !is.numeric(sheet)) {
    cli::cli_abort(
      "{.arg sheet} must be a character vector, an integer vector, or {.code NULL}."
    )
  }

  # Validate against both files
  validate_sheet(sheet, sheets1, file1)
  validate_sheet(sheet, sheets2, file2)

  # Convert indices to names
  if (is.numeric(sheet)) {
    return(sheets1[sheet])
  }
  sheet
}

#' @noRd
read_sheet_names <- function(path) {
  tryCatch(
    tidyxl::xlsx_sheet_names(path),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to read {.file {path}}.",
        "i" = "The file may be corrupted or not a valid Excel file.",
        "x" = conditionMessage(e)
      ), call = NULL)
    }
  )
}

#' @noRd
read_cells <- function(path, sheet) {
  tryCatch(
    tidyxl::xlsx_cells(path, sheets = sheet),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to read cells from {.file {path}}.",
        "i" = "The file may be corrupted or password-protected.",
        "x" = conditionMessage(e)
      ), call = NULL)
    }
  )
}


# --- CLI output helpers -------------------------------------------------------

#' @noRd
emit_diff_summary <- function(differences) {
  n <- nrow(differences)
  if (n == 0L) {
    cli::cli_inform("{.pkg v} No differences found.")
    return(invisible())
  }
  counts <- table(differences$status)
  parts <- vapply(names(counts), function(s) {
    paste0(counts[[s]], " ", s)
  }, character(1))
  cli::cli_inform(
    "{.pkg !} Found {n} difference{?s} ({paste(parts, collapse = ', ')})."
  )
}
