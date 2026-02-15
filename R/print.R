#' @export
print.excelcompare_diff <- function(x, ...) {
  n <- nrow(x)

  if (n == 0L) {
    cli::cli_h1("Excel Comparison")
    cli::cli_alert_success("No differences found.")
    return(invisible(x))
  }

  sheets <- unique(x$sheet)

  for (sn in sheets) {
    sheet_diffs <- x[x$sheet == sn, , drop = FALSE]
    nd <- nrow(sheet_diffs)

    cli::cli_h1("Excel Comparison")
    cli::cli_text("Sheet: {.val {sn}} | {nd} difference{?s}")
    cli::cli_text("")

    for (i in seq_len(nd)) {
      row_i <- sheet_diffs[i, , drop = FALSE]
      label <- format_diff_line(row_i)
      cli::cli_text(label)
    }
  }

  invisible(x)
}

#' @export
summary.excelcompare_diff <- function(object, ...) {
  n <- nrow(object)

  if (n == 0L) {
    cli::cli_alert_success("No differences found.")
    return(invisible(object))
  }

  sheets <- unique(object$sheet)

  cli::cli_h1("Excel Comparison Summary")
  cli::cli_text("{n} difference{?s} across {length(sheets)} sheet{?s}")
  cli::cli_text("")

  for (sn in sheets) {
    sheet_diffs <- object[object$sheet == sn, , drop = FALSE]
    counts <- table(sheet_diffs$status)
    parts <- vapply(names(counts), function(s) {
      paste0(counts[[s]], " ", s)
    }, character(1))
    cli::cli_text("Sheet {.val {sn}}: {paste(parts, collapse = ', ')}")
  }

  invisible(object)
}


# --- Formatting helpers -------------------------------------------------------

#' Format a single diff line for display
#' @noRd
format_diff_line <- function(row) {
  addr <- row$address
  v1 <- format_cell_value(row$value1)
  v2 <- format_cell_value(row$value2)
  status <- row$status

  switch(status,
    modified = cli::format_inline(
      "  {addr}: {.field {v1}} -> {.field {v2}}     {.emph [modified]}"
    ),
    added = cli::format_inline(
      "  {addr}: {.emph (empty)} -> {.field {v2}}     {.emph [added]}"
    ),
    removed = cli::format_inline(
      "  {addr}: {.field {v1}} -> {.emph (empty)}     {.emph [removed]}"
    )
  )
}

#' Format a cell value for display (truncate long values)
#' @noRd
format_cell_value <- function(val) {
  if (is.na(val)) return("(empty)")
  s <- as.character(val)
  if (nchar(s) > 40) {
    s <- paste0(substr(s, 1, 37), "...")
  }
  s
}
