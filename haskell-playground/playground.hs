custom_second :: [a] -> a
custom_second x = head $ tail x

mydrop c xs = if c <= 0 || null xs
  then xs
  else let next = c - 1 in
         mydrop next $ tail xs
