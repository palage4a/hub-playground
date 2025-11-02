import Data.List as List

custom_second :: [a] -> a
custom_second x = head $ tail x

mydrop c xs = if c <= 0 || null xs
  then xs
  else let next = c - 1 in
         mydrop next $ tail xs

data Color = Red | Green | Yellow | Blue

say Red = "Red"
say Green = "Green"
say Yellow = "Yellow"
say _ = "Unknown color"



number1 :: Num a => a
number1 = 1 + 2 + 3 + 4

number2 :: Num a => a
number2 = number1 * number1

mm = print number2

data Animal = Wolf
  | Lion
  | Fox

type Zoo = [Animal]

z :: Zoo
z = [Wolf, Lion, Fox, Lion]

advice :: Animal -> String
advice Wolf = "Woof"
advice Lion = "Roooar"
advice Fox = "Roooar"

adviceForWholeZoo :: Zoo -> [String]
adviceForWholeZoo = map advice

zoomain = do
  putStrLn . List.intercalate ", " $ adviceForWholeZoo z


data User = MkUser
  { name :: String
   ,age :: Integer
   ,married :: Bool} deriving (Show)
