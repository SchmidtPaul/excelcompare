test_that("compare_xlsx detects differences between files", {
  file1 <- test_path("fixtures", "test1.xlsx")
  file2 <- test_path("fixtures", "test2.xlsx")

  result <- compare_xlsx(file1, file2)

  expect_s3_class(result, "excelcompare_diff")
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("sheet", "row", "col", "address", "value1", "value2", "status"))

  expect_gt(nrow(result), 0)
  expect_true("modified" %in% result$status)
})

test_that("compare_xlsx returns empty tibble for identical files", {
  file1 <- test_path("fixtures", "test1.xlsx")
  file1_copy <- test_path("fixtures", "test1_copy.xlsx")

  result <- compare_xlsx(file1, file1_copy)

  expect_s3_class(result, "excelcompare_diff")
  expect_equal(nrow(result), 0)
  # Empty result still has all columns
  expect_named(result, c("sheet", "row", "col", "address", "value1", "value2", "status"))
})

test_that("compare_xlsx errors on non-existent files", {
  expect_error(
    compare_xlsx("nonexistent.xlsx", test_path("fixtures", "test1.xlsx")),
    "File not found"
  )
  expect_error(
    compare_xlsx(test_path("fixtures", "test1.xlsx"), "nonexistent.xlsx"),
    "File not found"
  )
})

test_that("compare_xlsx result has correct column types", {
  file1 <- test_path("fixtures", "test1.xlsx")
  file2 <- test_path("fixtures", "test2.xlsx")

  result <- compare_xlsx(file1, file2)

  expect_type(result$sheet, "character")
  expect_type(result$row, "integer")
  expect_type(result$col, "integer")
  expect_type(result$address, "character")
  expect_type(result$status, "character")
})

# --- File extension validation ---

test_that("compare_xlsx rejects non-Excel file extensions", {
  tmp_csv <- tempfile(fileext = ".csv")
  tmp_xls <- tempfile(fileext = ".xls")
  f <- test_path("fixtures", "test1.xlsx")

  file.create(tmp_csv)
  file.create(tmp_xls)
  on.exit(unlink(c(tmp_csv, tmp_xls)))

  expect_error(compare_xlsx(tmp_csv, f), "Unsupported file format")
  expect_error(compare_xlsx(f, tmp_xls), "Unsupported file format")
})

# --- Sheet validation ---

test_that("compare_xlsx errors on invalid sheet name", {
  f <- test_path("fixtures", "test1.xlsx")
  expect_error(
    compare_xlsx(f, f, sheet = "NonExistent"),
    "not found"
  )
})

test_that("compare_xlsx errors on out-of-range sheet index", {
  f <- test_path("fixtures", "test1.xlsx")
  expect_error(
    compare_xlsx(f, f, sheet = 99),
    "out of range"
  )
})

test_that("compare_xlsx errors on invalid sheet type", {
  f <- test_path("fixtures", "test1.xlsx")
  expect_error(
    compare_xlsx(f, f, sheet = TRUE),
    "sheet"
  )
})

# --- Corrupt file handling ---

test_that("compare_xlsx gives clear error for corrupt file", {
  corrupt <- test_path("fixtures", "test_corrupt.xlsx")
  f <- test_path("fixtures", "test1.xlsx")
  expect_error(compare_xlsx(corrupt, f), "Failed to read")
})

# --- .xlsm support ---

test_that("compare_xlsx works with .xlsm files", {
  xlsm <- test_path("fixtures", "test_macro.xlsm")
  result <- compare_xlsx(xlsm, xlsm)
  expect_s3_class(result, "excelcompare_diff")
  expect_equal(nrow(result), 0)
})

# --- Parameter validation ---

test_that("compare_xlsx validates tolerance parameter", {
  f <- test_path("fixtures", "test1.xlsx")
  expect_error(compare_xlsx(f, f, tolerance = -1), "tolerance")
  expect_error(compare_xlsx(f, f, tolerance = "a"), "tolerance")
  expect_error(compare_xlsx(f, f, tolerance = c(1, 2)), "tolerance")
})

test_that("compare_xlsx validates na_equals_zero parameter", {
  f <- test_path("fixtures", "test1.xlsx")
  expect_error(compare_xlsx(f, f, na_equals_zero = "yes"), "na_equals_zero")
  expect_error(compare_xlsx(f, f, na_equals_zero = c(TRUE, FALSE)), "na_equals_zero")
})

# --- Numeric tolerance ---

test_that("tolerance = NULL detects all numeric differences as strings", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2)
  expect_equal(nrow(result), 5)
  expect_true(all(result$status == "modified"))
})

test_that("tolerance absorbs small numeric differences", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2, tolerance = 0.05)
  expect_equal(nrow(result), 0)
})

test_that("tight tolerance still catches larger differences", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2, tolerance = 0.02)
  expect_equal(nrow(result), 4)
})

test_that("tolerance = 0 gives type-aware exact comparison", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  result <- compare_xlsx(f1, f1, tolerance = 0)
  expect_equal(nrow(result), 0)
})

# --- NA equals zero ---

test_that("na_equals_zero = FALSE detects NA vs 0 differences", {
  f1 <- test_path("fixtures", "test_na_zero.xlsx")
  f2 <- test_path("fixtures", "test_na_zero_v2.xlsx")

  result <- compare_xlsx(f1, f2, na_equals_zero = FALSE)
  expect_equal(nrow(result), 2)
})

test_that("na_equals_zero = TRUE treats NA/0 as identical", {
  f1 <- test_path("fixtures", "test_na_zero.xlsx")
  f2 <- test_path("fixtures", "test_na_zero_v2.xlsx")

  result <- compare_xlsx(f1, f2, na_equals_zero = TRUE)
  expect_equal(nrow(result), 0)
})

# --- Multi-sheet support ---

test_that("sheet = NULL compares all shared sheets", {
  f1 <- test_path("fixtures", "test_multi_sheet.xlsx")
  f2 <- test_path("fixtures", "test_multi_sheet_v2.xlsx")

  result <- compare_xlsx(f1, f2, sheet = NULL)
  expect_s3_class(result, "excelcompare_diff")

  # Both Data and Summary sheets have differences
  expect_true(all(c("Data", "Summary") %in% result$sheet))
  # Data: 2 diffs (A3, B4), Summary: 1 diff (A2) = 3 total
  expect_equal(nrow(result), 3)
})

test_that("sheet vector compares multiple specific sheets", {
  f1 <- test_path("fixtures", "test_multi_sheet.xlsx")
  f2 <- test_path("fixtures", "test_multi_sheet_v2.xlsx")

  # Compare only Data sheet
  result <- compare_xlsx(f1, f2, sheet = "Data")
  expect_equal(nrow(result), 2)
  expect_true(all(result$sheet == "Data"))

  # Compare both by name
  result_both <- compare_xlsx(f1, f2, sheet = c("Data", "Summary"))
  expect_equal(nrow(result_both), 3)
})

test_that("sheet index vector works", {
  f1 <- test_path("fixtures", "test_multi_sheet.xlsx")
  f2 <- test_path("fixtures", "test_multi_sheet_v2.xlsx")

  result <- compare_xlsx(f1, f2, sheet = c(1, 2))
  expect_equal(nrow(result), 3)
})

test_that("sheet = NULL with extra sheets only compares shared ones", {
  f1 <- test_path("fixtures", "test_multi_sheet.xlsx")
  f2 <- test_path("fixtures", "test_extra_sheets.xlsx")

  # test_multi_sheet has Data + Summary; test_extra_sheets has Data + Summary + Notes
  # Shared: Data, Summary. File 1 has no differences (same data).
  result <- compare_xlsx(f1, f2, sheet = NULL)
  expect_false("Notes" %in% result$sheet)
})

# --- Edge cases ---

test_that("compare_xlsx handles empty sheets", {
  empty <- test_path("fixtures", "test_empty_sheet.xlsx")
  result <- compare_xlsx(empty, empty)
  expect_equal(nrow(result), 0)
})

test_that("compare_xlsx handles single-cell files", {
  f1 <- test_path("fixtures", "test_single_cell.xlsx")
  f2 <- test_path("fixtures", "test_single_cell_v2.xlsx")

  result <- compare_xlsx(f1, f2)
  # Header "A" is same, value differs (hello vs world)
  expect_equal(nrow(result), 1)
  expect_equal(result$status, "modified")
})

# --- Output schema ---

test_that("output always has sheet column and never value_num", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2, tolerance = 0.01)
  expect_false("value_num1" %in% names(result))
  expect_false("value_num2" %in% names(result))
  expect_named(result, c("sheet", "row", "col", "address", "value1", "value2", "status"))
})

test_that("default parameters preserve original behavior", {
  f1 <- test_path("fixtures", "test1.xlsx")
  f2 <- test_path("fixtures", "test2.xlsx")

  result_default <- compare_xlsx(f1, f2)
  result_explicit <- compare_xlsx(f1, f2, tolerance = NULL, na_equals_zero = FALSE)
  expect_equal(result_default, result_explicit)
})

# --- Print / Summary ---

test_that("print method produces snapshot output", {
  f1 <- test_path("fixtures", "test1.xlsx")
  f2 <- test_path("fixtures", "test2.xlsx")
  result <- compare_xlsx(f1, f2)
  expect_snapshot(print(result))
})

test_that("print method handles no differences", {
  f1 <- test_path("fixtures", "test1.xlsx")
  result <- compare_xlsx(f1, f1)
  expect_snapshot(print(result))
})

test_that("summary method produces snapshot output", {
  f1 <- test_path("fixtures", "test_multi_sheet.xlsx")
  f2 <- test_path("fixtures", "test_multi_sheet_v2.xlsx")
  result <- compare_xlsx(f1, f2, sheet = NULL)
  expect_snapshot(summary(result))
})
