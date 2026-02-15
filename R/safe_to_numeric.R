#' Convert value to numeric handling multiple decimal separators
#'
#' Attempts to convert a value to numeric. If the value is already numeric,
#' returns it as-is. If it's a character string, tries parsing with `"."` as
#' decimal separator first, then `","` if that fails. Only accepts strings that
#' contain only digits, separators, and an optional leading minus sign.
#'
#' @param val A value of any type to convert to numeric.
#'
#' @return Numeric value or `NA` if conversion fails.
#'
#' @examples
#' safe_to_numeric(10.5)
#' safe_to_numeric("10.5")
#' safe_to_numeric("10,5")
#' safe_to_numeric("-3.14")
#' safe_to_numeric("text")
#'
#' @export
safe_to_numeric <- function(val) {
  # Already numeric
  if (is.numeric(val)) {
    return(val)
  }

  # Not character — try direct conversion
  if (!is.character(val)) {
    return(suppressWarnings(as.numeric(val)))
  }

  # Only accept strings that look like numbers (digits, separators, optional minus)
  if (!grepl("^-?[0-9.,]+$", val)) {
    return(NA_real_)
  }

  has_comma <- grepl(",", val)
  has_dot <- grepl("\\.", val)

  # Comma only → comma as decimal

  if (has_comma && !has_dot) {
    return(suppressWarnings(readr::parse_number(
      val,
      locale = readr::locale(decimal_mark = ",", grouping_mark = "")
    )))
  }

  # Dot only → dot as decimal
  if (has_dot && !has_comma) {
    return(suppressWarnings(readr::parse_number(
      val,
      locale = readr::locale(decimal_mark = ".", grouping_mark = "")
    )))
  }

  # Both or neither → try dot first, then comma
  result <- suppressWarnings(readr::parse_number(
    val,
    locale = readr::locale(decimal_mark = ".", grouping_mark = "")
  ))

  if (is.na(result)) {
    result <- suppressWarnings(readr::parse_number(
      val,
      locale = readr::locale(decimal_mark = ",", grouping_mark = "")
    ))
  }

  result
}
