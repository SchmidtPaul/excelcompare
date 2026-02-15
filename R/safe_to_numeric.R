#' Convert values to numeric handling multiple decimal separators
#'
#' Attempts to convert values to numeric. If the input is already numeric,
#' returns it as-is. Character strings are parsed with support for:
#' - Dot-decimal (`"10.5"`) and comma-decimal (`"10,5"`) notation
#' - Scientific notation (`"1e-5"`, `"2.5E+10"`)
#' - Thousand separators when both dot and comma are present
#'   (`"1.234,56"` European or `"1,234.56"` US)
#'
#' The function is vectorized: when given a character vector, each element
#' is parsed independently.
#'
#' @param val A numeric, character, or other vector to convert to numeric.
#'
#' @return Numeric vector of the same length, with `NA` for values that
#'   cannot be parsed.
#'
#' @examples
#' safe_to_numeric(10.5)
#' safe_to_numeric("10.5")
#' safe_to_numeric("10,5")
#' safe_to_numeric("-3.14")
#' safe_to_numeric("1e-5")
#' safe_to_numeric("1.234,56")
#' safe_to_numeric(c("10.5", "10,5", "text", "1e-3"))
#'
#' @export
safe_to_numeric <- function(val) {
  if (is.numeric(val)) return(val)
  if (!is.character(val)) return(suppressWarnings(as.numeric(val)))

  n <- length(val)
  result <- rep(NA_real_, n)

  # Accept: digits, dot, comma, optional minus, optional sci notation

  looks_numeric <- grepl("^-?[0-9.,]+([eE][+-]?[0-9]+)?$", val)
  idx <- which(looks_numeric)
  if (length(idx) == 0L) return(result)

  v <- val[idx]
  has_comma <- grepl(",", v)
  has_dot <- grepl("\\.", v)

  # No comma → as.numeric handles dot-decimal and sci notation natively
  no_comma <- !has_comma
  if (any(no_comma)) {
    result[idx[no_comma]] <- suppressWarnings(as.numeric(v[no_comma]))
  }

  # Comma only (no dot) → comma as decimal separator
  comma_only <- has_comma & !has_dot
  if (any(comma_only)) {
    result[idx[comma_only]] <- suppressWarnings(readr::parse_number(
      v[comma_only],
      locale = readr::locale(decimal_mark = ",", grouping_mark = "")
    ))
  }

  # Both dot and comma → last separator determines decimal mark
  both <- has_comma & has_dot
  if (any(both)) {
    bi <- which(both)
    for (j in bi) {
      s <- v[j]
      last_comma <- max(gregexpr(",", s)[[1L]])
      last_dot <- max(gregexpr("\\.", s)[[1L]])
      if (last_comma > last_dot) {
        # European: 1.234,56
        parsed <- suppressWarnings(readr::parse_number(
          s, locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ))
      } else {
        # US: 1,234.56
        parsed <- suppressWarnings(readr::parse_number(
          s, locale = readr::locale(decimal_mark = ".", grouping_mark = ",")
        ))
      }
      result[idx[j]] <- parsed
    }
  }

  result
}
