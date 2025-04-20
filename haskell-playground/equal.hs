adds :: Integer -> Integer -> Integer -> Integer
adds a b c = a + b + c

lastButOne = head . reverse . init


say :: Integer -> String
say 1   = "You are Red!"
say 2  = "You are Blue!"
say 3 = "You are Green!"
say _ = "You are moron"


customMap func [] = []
customMap func (x:xs) = func x:(customMap func xs)
