# print method produces snapshot output

    Code
      print(result)
    Message
      
      -- Excel Comparison ------------------------------------------------------------
      Sheet: "Sheet1" | 2 differences
      
      A1: Title -> Different Title [modified]
      A4: 2 -> 99 [modified]

# print method handles no differences

    Code
      print(result)
    Message
      
      -- Excel Comparison ------------------------------------------------------------
      v No differences found.

# summary method produces snapshot output

    Code
      summary(result)
    Message
      
      -- Excel Comparison Summary ----------------------------------------------------
      3 differences across 2 sheets
      
      Sheet "Data": 2 modified
      Sheet "Summary": 1 modified

