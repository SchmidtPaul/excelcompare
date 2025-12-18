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
#' # Compare two Excel files
#' differences <- compare_xlsx("report_v1.xlsx", "report_v2.xlsx")
#'
#' # Compare a specific sheet by name
#' differences <- compare_xlsx("data1.xlsx", "data2.xlsx", sheet = "Summary")
#'
#' # Compare the second sheet by index
#' differences <- compare_xlsx("file1.xlsx", "file2.xlsx", sheet = 2)
#' }
compare_xlsx <- function(file1, file2, sheet = 1) {
  # Validate inputs
  if (!file.exists(file1)) {
    cli::cli_abort("File not found: {.file {file1}}")
  }
  if (!file.exists(file2)) {
    cli::cli_abort("File not found: {.file {file2}}")
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
      !identical_values(.data$value1, .data$value2)
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
#' @return A tibble with columns: row, col, address, value.
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
      )
    ) |>
    dplyr::select("row", "col", "address", "value")
}

#' Check if Two Values are Identical
#'
#' Handles NA comparison correctly (NA == NA returns TRUE).
#'
#' @param x First value.
#' @param y Second value.
#'
#' @return Logical vector.
#'
#' @noRd
identical_values <- function(x, y) {
  (is.na(x) & is.na(y)) | (!is.na(x) & !is.na(y) & x == y)
}
