# Helper to call values_are_equal with scalar inputs
vae <- function(v1, v2, n1 = NA_real_, n2 = NA_real_,
                tolerance = NULL, na_equals_zero = FALSE) {
  values_are_equal(v1, v2, n1, n2, tolerance, na_equals_zero)
}

# --- Basic equality ---

test_that("both NA returns TRUE", {
  expect_true(vae(NA_character_, NA_character_))
})

test_that("identical strings return TRUE", {
  expect_true(vae("hello", "hello"))
})

test_that("different strings return FALSE", {
  expect_false(vae("hello", "world"))
})

test_that("one NA returns FALSE", {
  expect_false(vae(NA_character_, "hello"))
  expect_false(vae("hello", NA_character_))
})

# --- NA-equals-zero ---

test_that("NA vs 0 returns TRUE when na_equals_zero = TRUE", {
  expect_true(vae(NA_character_, "0", NA_real_, 0, na_equals_zero = TRUE))
  expect_true(vae("0", NA_character_, 0, NA_real_, na_equals_zero = TRUE))
})

test_that("NA vs 0 returns FALSE when na_equals_zero = FALSE", {
  expect_false(vae(NA_character_, "0", NA_real_, 0, na_equals_zero = FALSE))
})

test_that("NA vs non-zero returns FALSE even with na_equals_zero", {
  expect_false(vae(NA_character_, "5", NA_real_, 5, na_equals_zero = TRUE))
})

# --- Numeric tolerance with num columns ---

test_that("tolerance comparison uses num columns", {
  expect_true(vae("10", "10.04", 10, 10.04, tolerance = 0.05))
  expect_false(vae("10", "10.06", 10, 10.06, tolerance = 0.05))
})

test_that("tolerance = 0 means exact numeric equality", {
  expect_true(vae("1", "1.0", 1, 1, tolerance = 0))
  expect_false(vae("1", "1.001", 1, 1.001, tolerance = 0))
})

# --- Decimal separator normalization (character fallback) ---

test_that("comma decimal parsed when num columns are NA", {
  expect_true(vae("10.5", "10,5", NA_real_, NA_real_, tolerance = 0))
})

test_that("negative comma decimal parsed", {
  expect_true(vae("-3.14", "-3,14", NA_real_, NA_real_, tolerance = 0))
})

# --- String fallback with tolerance ---

test_that("non-numeric strings compared as strings with tolerance set", {
  expect_true(vae("abc", "abc", NA_real_, NA_real_, tolerance = 0.05))
  expect_false(vae("abc", "def", NA_real_, NA_real_, tolerance = 0.05))
})

# --- Vectorized ---

test_that("vectorized comparison works", {
  v1 <- c("a", NA_character_, "10", "hello")
  v2 <- c("a", NA_character_, "10.04", "world")
  n1 <- c(NA_real_, NA_real_, 10, NA_real_)
  n2 <- c(NA_real_, NA_real_, 10.04, NA_real_)

  result <- values_are_equal(v1, v2, n1, n2, tolerance = 0.05,
                             na_equals_zero = FALSE)
  expect_equal(result, c(TRUE, TRUE, TRUE, FALSE))
})

# --- Backward compatibility (tolerance = NULL) ---

test_that("tolerance NULL gives exact string comparison", {
  # Numeric representations that differ as strings
  expect_false(vae("1.0", "1.00", 1, 1, tolerance = NULL))
  # Identical strings
  expect_true(vae("1.0", "1.0", 1, 1, tolerance = NULL))
})

# --- Edge cases ---

test_that("both NA with na_equals_zero still returns TRUE", {
  expect_true(vae(NA_character_, NA_character_, NA_real_, NA_real_,
                   na_equals_zero = TRUE))
})

test_that("empty strings compared correctly", {
  expect_true(vae("", ""))
  expect_false(vae("", "x"))
})
