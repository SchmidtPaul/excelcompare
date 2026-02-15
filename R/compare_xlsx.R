#' Compare Two Excel Files Cell by Cell
#'
#' Compares two Excel files (.xlsx) at the cell level, identifying differences
#' in content based on cell position (row, column). This function captures all
#' cells in a worksheet, including titles, footnotes, and annotations outside
#' the main data table.
#'
#' @param file1 Path to the first Excel file (.xlsx or .xlsm).
#' @param file2 Path to the second Excel file (.xlsx or .xlsm).
#' @param sheet Sheet to compare. Can be a sheet name (character) or index
#'   (integer). Defaults to 1 (first sheet).
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
#'     \item{row}{Row number of the cell}
#'     \item{col}{Column number of the cell}
#'     \item{address}{Excel cell address (e.g., "A1", "B2")}
#'     \item{value1}{Cell value in file1 (NA if cell doesn't exist)}
#'     \item{value2}{Cell value in file2 (NA if cell doesn't exist)}
#'     \item{status}{Type of difference: "modified", "added", or "removed"}
#'   }
#'   Returns an empty tibble if files are identical.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Compare two Excel files (exact string comparison)
#' differences <- compare_xlsx("report_v1.xlsx", "report_v2.xlsx")
#'
#' # Compare with numeric tolerance
#' differences <- compare_xlsx("file1.xlsx", "file2.xlsx", tolerance = 0.05)
#'
#' # Treat NA and 0 as identical
#' differences <- compare_xlsx("file1.xlsx", "file2.xlsx", na_equals_zero = TRUE)
#'
#' # Compare a specific sheet
#' differences <- compare_xlsx("data1.xlsx", "data2.xlsx", sheet = "Summary")
#' }
compare_xlsx <- function(file1, file2, sheet = 1,
                         tolerance = NULL, na_equals_zero = FALSE) {
  # Validate inputs
  if (!file.exists(file1)) {
    cli::cli_abort("File not found: {.file {file1}}")
  }
  if (!file.exists(file2)) {
    cli::cli_abort("File not found: {.file {file2}}")
  }
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

  # Read cells from both files
  cells1 <- tidyxl::xlsx_cells(file1, sheets = sheet)
  cells2 <- tidyxl::xlsx_cells(file2, sheets = sheet)

  # Extract cell values (coalesce different value types into single column)
  cells1 <- extract_cell_values(cells1)
  cells2 <- extract_cell_values(cells2)

  # Full join on position to find all differences
  comparison <- dplyr::full_join(
    cells1,
    cells2,
    by = c("row", "col", "address"),
    suffix = c("1", "2")
  )

  # Identify differences
  differences <- comparison |>
    dplyr::filter(
      !values_are_equal(
        .data$value1, .data$value2,
        .data$value_num1, .data$value_num2,
        tolerance = tolerance,
        na_equals_zero = na_equals_zero
      )
    ) |>
    dplyr::mutate(
      status = dplyr::case_when(
        is.na(.data$value1) ~ "added",
        is.na(.data$value2) ~ "removed",
        TRUE ~ "modified"
      )
    ) |>
    dplyr::select("row", "col", "address", "value1", "value2", "status") |>
    dplyr::arrange(.data$row, .data$col)

  differences
}

#' Extract Cell Values into a Single Column
#'
#' Internal helper function that coalesces tidyxl's multiple value columns
#' (character, numeric, logical, date) into a single character representation.
#'
#' @param cells A tibble from [tidyxl::xlsx_cells()].
#'
#' @return A tibble with columns: row, col, address, value, value_num.
#'
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
