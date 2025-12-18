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
