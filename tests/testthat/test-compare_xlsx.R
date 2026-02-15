test_that("compare_xlsx detects differences between files", {
  file1 <- test_path("fixtures", "test1.xlsx")
  file2 <- test_path("fixtures", "test2.xlsx")

  result <- compare_xlsx(file1, file2)

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("row", "col", "address", "value1", "value2", "status"))


  # Should detect differences in title (row 1) and data (row 3, col A = 99 vs 2)
  expect_gt(nrow(result), 0)

  # Check that modified cells are detected
  expect_true("modified" %in% result$status)
})

test_that("compare_xlsx returns empty tibble for identical files",
{
  file1 <- test_path("fixtures", "test1.xlsx")
  file1_copy <- test_path("fixtures", "test1_copy.xlsx")

  result <- compare_xlsx(file1, file1_copy)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
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

test_that("compare_xlsx result has correct structure", {
  file1 <- test_path("fixtures", "test1.xlsx")
  file2 <- test_path("fixtures", "test2.xlsx")

  result <- compare_xlsx(file1, file2)

  expect_type(result$row, "integer")
  expect_type(result$col, "integer")
  expect_type(result$address, "character")
  expect_type(result$status, "character")
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
  # 10 vs 10.03, 10.5 vs 10.54, -3.14 vs -3.18, "10,5" vs "10,54", 0 vs 0.01
  expect_equal(nrow(result), 5)
  expect_true(all(result$status == "modified"))
})

test_that("tolerance absorbs small numeric differences", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2, tolerance = 0.05)
  # All differences are <= 0.05, including comma-decimal text

  expect_equal(nrow(result), 0)
})

test_that("tight tolerance still catches larger differences", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2, tolerance = 0.02)
  # 10 vs 10.03 (diff 0.03 > 0.02), 10.5 vs 10.54 (0.04 > 0.02),
  # -3.14 vs -3.18 (0.04 > 0.02), "10,5" vs "10,54" (0.04 > 0.02)
  # 0 vs 0.01 (0.01 <= 0.02) — passes
  expect_equal(nrow(result), 4)
})

test_that("tolerance = 0 gives type-aware exact comparison", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")

  # Same file compared to itself → no differences even with tolerance = 0
  result <- compare_xlsx(f1, f1, tolerance = 0)
  expect_equal(nrow(result), 0)
})

# --- NA equals zero ---

test_that("na_equals_zero = FALSE detects NA vs 0 differences", {
  f1 <- test_path("fixtures", "test_na_zero.xlsx")
  f2 <- test_path("fixtures", "test_na_zero_v2.xlsx")

  result <- compare_xlsx(f1, f2, na_equals_zero = FALSE)
  # Row 3: NA vs 0, Row 4: 0 vs NA
  expect_equal(nrow(result), 2)
})

test_that("na_equals_zero = TRUE treats NA/0 as identical", {
  f1 <- test_path("fixtures", "test_na_zero.xlsx")
  f2 <- test_path("fixtures", "test_na_zero_v2.xlsx")

  result <- compare_xlsx(f1, f2, na_equals_zero = TRUE)
  expect_equal(nrow(result), 0)
})

# --- Backward compatibility ---

test_that("default parameters preserve original behavior", {
  f1 <- test_path("fixtures", "test1.xlsx")
  f2 <- test_path("fixtures", "test2.xlsx")

  result_default <- compare_xlsx(f1, f2)
  result_explicit <- compare_xlsx(f1, f2, tolerance = NULL, na_equals_zero = FALSE)
  expect_equal(result_default, result_explicit)
})

# --- Output schema ---

test_that("output never contains value_num columns", {
  f1 <- test_path("fixtures", "test_numeric.xlsx")
  f2 <- test_path("fixtures", "test_numeric_v2.xlsx")

  result <- compare_xlsx(f1, f2, tolerance = 0.01)
  expect_false("value_num1" %in% names(result))
  expect_false("value_num2" %in% names(result))
  expect_named(result, c("row", "col", "address", "value1", "value2", "status"))
})
