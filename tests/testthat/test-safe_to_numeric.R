test_that("safe_to_numeric handles numeric input", {
  expect_equal(safe_to_numeric(10.5), 10.5)
  expect_equal(safe_to_numeric(0), 0)
  expect_equal(safe_to_numeric(-5.3), -5.3)
})

test_that("safe_to_numeric handles character with point decimal", {
  expect_equal(safe_to_numeric("10.5"), 10.5)
  expect_equal(safe_to_numeric("10.049999999999999"), 10.049999999999999)
  expect_equal(safe_to_numeric("0.1"), 0.1)
})

test_that("safe_to_numeric handles character with comma decimal", {
  expect_equal(safe_to_numeric("10,5"), 10.5)
  expect_equal(safe_to_numeric("0,1"), 0.1)
  expect_equal(safe_to_numeric("1234,56"), 1234.56)
})

test_that("safe_to_numeric handles non-numeric strings", {
  expect_true(is.na(safe_to_numeric("text")))
  expect_true(is.na(safe_to_numeric("abc123")))
  expect_true(is.na(safe_to_numeric("")))
})

test_that("safe_to_numeric handles NA", {
  expect_true(is.na(safe_to_numeric(NA)))
  expect_true(is.na(safe_to_numeric(NA_character_)))
  expect_true(is.na(safe_to_numeric(NA_real_)))
})

test_that("safe_to_numeric handles negative numbers", {
  expect_equal(safe_to_numeric("-10.5"), -10.5)
  expect_equal(safe_to_numeric("-10,5"), -10.5)
  expect_equal(safe_to_numeric("-0.1"), -0.1)
})
