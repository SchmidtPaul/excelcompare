#' Check if two value vectors are equal with optional tolerance
#'
#' Vectorized comparison logic that supports numeric tolerance,
#' decimal separator normalization, and NA-equals-zero semantics.
#'
#' @param value1,value2 Character vectors of cell display values.
#' @param num1,num2 Numeric vectors of raw cell values (from tidyxl).
#' @param tolerance Numeric tolerance or `NULL` for exact string comparison.
#' @param na_equals_zero If `TRUE`, treat (NA, 0) pairs as equal.
#'
#' @return Logical vector.
#'
#' @noRd
values_are_equal <- function(value1, value2, num1, num2,
                             tolerance, na_equals_zero) {
  n <- length(value1)
  result <- rep(FALSE, n)

  na1 <- is.na(value1)
  na2 <- is.na(value2)

  # Step 1: Both NA → TRUE
  both_na <- na1 & na2
  result[both_na] <- TRUE

  # Step 2: NA-equals-zero
  if (na_equals_zero) {
    na_zero <- (na1 & !na2 & !is.na(num2) & num2 == 0) |
               (na2 & !na1 & !is.na(num1) & num1 == 0)
    result[na_zero] <- TRUE
  }

  # Remaining: neither already resolved
  remaining <- !result & !both_na

  if (!is.null(tolerance)) {
    # Step 3: Both have numeric values → tolerance comparison
    has_nums <- remaining & !is.na(num1) & !is.na(num2)
    result[has_nums] <- abs(num1[has_nums] - num2[has_nums]) <= tolerance

    # Step 4: Numeric NA but character parseable → safe_to_numeric fallback
    need_parse <- remaining & !has_nums & !na1 & !na2
    if (any(need_parse)) {
      parsed1 <- vapply(value1[need_parse], safe_to_numeric, numeric(1))
      parsed2 <- vapply(value2[need_parse], safe_to_numeric, numeric(1))
      both_parsed <- !is.na(parsed1) & !is.na(parsed2)
      idx <- which(need_parse)
      result[idx[both_parsed]] <-
        abs(parsed1[both_parsed] - parsed2[both_parsed]) <= tolerance
      # Non-parseable: fallback to string comparison
      result[idx[!both_parsed]] <-
        value1[need_parse][!both_parsed] == value2[need_parse][!both_parsed]
    }
  } else {
    # Step 5: Exact string comparison (NA-safe)
    string_cmp <- remaining & !na1 & !na2
    result[string_cmp] <- value1[string_cmp] == value2[string_cmp]
  }

  result
}
