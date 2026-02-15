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

# --- Scientific notation ---

test_that("safe_to_numeric handles scientific notation", {
  expect_equal(safe_to_numeric("1e-5"), 1e-5)
  expect_equal(safe_to_numeric("2.5E+10"), 2.5e+10)
  expect_equal(safe_to_numeric("1E3"), 1000)
  expect_equal(safe_to_numeric("-1.5e-3"), -0.0015)
})

# --- Thousand separators ---

test_that("safe_to_numeric handles European thousand separators", {
  expect_equal(safe_to_numeric("1.234,56"), 1234.56)
  expect_equal(safe_to_numeric("1.000.000,50"), 1000000.50)
})

test_that("safe_to_numeric handles US thousand separators", {
  expect_equal(safe_to_numeric("1,234.56"), 1234.56)
  expect_equal(safe_to_numeric("1,000,000.50"), 1000000.50)
})

# --- Vectorized ---

test_that("safe_to_numeric is vectorized", {
  input <- c("10.5", "10,5", "text", "1e-3", NA_character_)
  result <- safe_to_numeric(input)
  expect_length(result, 5)
  expect_equal(result[1], 10.5)
  expect_equal(result[2], 10.5)
  expect_true(is.na(result[3]))
  expect_equal(result[4], 0.001)
  expect_true(is.na(result[5]))
})

test_that("safe_to_numeric returns numeric vector for character input", {
  expect_type(safe_to_numeric(c("1", "2", "3")), "double")
})

test_that("safe_to_numeric handles empty character vector", {
  result <- safe_to_numeric(character(0))
  expect_length(result, 0)
  expect_type(result, "double")
})
