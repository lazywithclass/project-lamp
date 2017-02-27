module Main where

import Prelude
import Data.List
import Data.Tuple
import Data.Maybe
import Control.Monad.Eff.Console (logShow)
import Unsafe.Coerce (unsafeCoerce)
import Test.QuickCheck (class Arbitrary, quickCheck)
import Test.QuickCheck.Gen (chooseInt)

data Lam = Var String
         | Abs String Lam
         | Lam Lam

identity = Abs "x" (Var "x")           
id = \x -> x

undefined :: forall a. a
undefined = unsafeCoerce unit

quicksort :: forall a. (Ord a) => List a -> List a
quicksort Nil    = Nil
quicksort (x:xs) = xsLess <> (singleton x) <> xsMore
  where xsLess = quicksort (filter (\a -> a <= x) xs)
        xsMore = quicksort (filter (\a -> a > x) xs)
                 
---| from here
data Nat = Zero
         | Add1 Nat

two :: Nat
two = Add1 $ Add1 Zero

five :: Nat
five = Add1 $ Add1 $ Add1 two

---| interface 
derive instance eqNat :: Eq Nat

instance showNat :: Show Nat where
  show n = show $ toInt n

instance arbNat :: Arbitrary Nat where
  arbitrary = do
    -- the second param of `chooseInt` needs to be relatively small
    x <- chooseInt 0 (100)
    pure $ fromInt x

toInt :: Nat -> Int
toInt = foldNat 0 (\acc -> 1 + acc)

fromInt :: Int -> Nat
fromInt x | x <= 0 = Zero
fromInt x = Add1 $ fromInt (x-1)

-- add two natural numbers together.
plus :: Nat -> Nat -> Nat
plus Zero     y = y
plus (Add1 x) y = Add1 (x `plus` y)

-- multiply two natural numbers.
times :: Nat -> Nat -> Nat
times Zero     _ = Zero
times (Add1 x) y = (x `times` y) `plus` y

-- pow raises its first argument to the power of the
-- second argument.
pow :: Nat -> Nat -> Nat
pow _ Zero     = Add1 Zero
pow x (Add1 y) = (x `pow` y) `times` x 
                 
---| exercises
foldNat :: forall a. a -> (a -> a) -> Nat -> a
foldNat base rec Zero     = base
foldNat base rec (Add1 n) = foldNat (rec base) rec n

plusFold :: Nat -> Nat -> Nat
plusFold m n = foldNat n Add1 m
-- plus = undefined

timesFold :: Nat -> Nat -> Nat
timesFold m n = foldNat Zero (\acc -> acc `plusFold` n) m

powFold :: Nat -> Nat -> Nat
powFold m n = foldNat (Add1 Zero) (\acc -> acc `timesFold` m) n

fact :: Nat -> Nat
fact Zero     = Add1 Zero
fact (Add1 n) = (Add1 n) `times` (fact n)

factFold :: Nat -> Nat
factFold n = snd $ foldNat
             (Tuple Zero (Add1 Zero))
             (\t -> case t of
                 Tuple nat r -> Tuple (Add1 n) (times (Add1 nat) r))
             n

---| properties
factProp :: Nat -> Boolean
factProp x | (toInt x) > 5 = true
factProp n = fact n == factFold n

plusId :: Nat -> Boolean
plusId n = n `plusFold` Zero == n

plusFoldIsPlus :: Nat -> Nat -> Boolean
plusFoldIsPlus m n = m `plus` n == m `plusFold` n

timesFoldIsTimes :: Nat -> Nat -> Boolean
timesFoldIsTimes m n = m `times` n == m `timesFold` n

powFoldIsPow :: Nat -> Nat -> Boolean
powFoldIsPow m n = m `pow` n == m `powFold` n

timesId :: Nat -> Boolean
timesId n = n `timesFold` (Add1 Zero) == n

powId :: Nat -> Boolean
powId n = n `powFold` (Add1 Zero) == n

-- these are variables
x = 5
y = 6

-- this is a function
foo1 = \x -> x

-- this is also a function
foo2 f x = \y -> f x

-- this is how to apply functions
app1 = foo1 x
app2 = foo2 foo1 y x


user = undefined

main = do
  logShow $ quicksort (5 : 4 : 10 : 2 : 0 : Nil)
  -- quickCheck factProp
  -- quickCheck plusId
  -- quickCheck plusFoldIsPlus
  -- quickCheck timesId
  -- quickCheck timesFoldIsTimes
  -- quickCheck powId
          -- quickCheck powFoldIsPow -- bad idea
          
