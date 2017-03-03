module Main where

import Prelude
import Data.List
import Data.Tuple
import Data.Maybe
-- import Control.Monad.Aff.Console
import Control.Monad.Eff.Console (logShow)
import Control.Monad.Eff.Exception.Unsafe
import Unsafe.Coerce (unsafeCoerce)
import Test.QuickCheck (class Arbitrary, quickCheck)
import Test.QuickCheck.Gen (chooseInt)

-- Black magic shit
undefined :: forall a. a
undefined = unsafeCoerce unit

error :: forall a. String -> a
error = unsafeThrow

-- Interpreter stuff
type Name = String

data Term = Num Number
          | Sub Term Term
          | Mul Term Term
          | Equ Term Term
          | If Term Term Term
          | Var Name
          | Let Name Term Term
          | Lam Name Term
          | App Term Term

-- data Value = N { n :: Number }
--            | B { b :: Boolean }
--            | F { f :: (Value -> Value) }
data Value = N Number
           | B Boolean
           | F (Value -> Value)

instance showValue :: Show Value where
  show (N x) = "N " <> show x-- .n
  show (B x) = "B " <> show x-- .b
  show (F _) = "Function"
  
type Env a = List { name :: Name, val :: a }

empty :: forall a. Env a
empty = Nil

extend :: forall a. Name -> a -> Env a -> Env a
extend n v e = { name : n, val : v } : e

lookUp :: forall a. Env a -> Name -> a
lookUp Nil n = error $ "unbound variable: " <> show n
lookUp (e:env) n | n == e.name = e.val
                 | otherwise   = lookUp env n

-- An interpreter
-- todo : fix the infer value thing
valueOf :: Env Value -> Term -> Value
valueOf e (Var x)     = lookUp e x
valueOf _ (Num i)     = N i
valueOf e (Sub x y)   = N (calcValue e (-) x y)
valueOf e (Mul x y)   = N (calcValue e (*) x y)
valueOf e (Equ x y)   = B (calcValue e (==) x y)
valueOf e (Let x v b) = valueOf (extend x (valueOf e v) e) b
valueOf e (If x y z)  = case valueOf e x of
  -- everything else is true (like Scheme!)
  B bool -> if bool then valueOf e y else valueOf e z
  _      -> valueOf e y 
valueOf e (Lam v b) = F (\a -> (valueOf (extend v a e) b))
valueOf e (App l r) = case valueOf e l of
  F foo -> foo (valueOf e r)
  _     -> error "cannot apply non function values"

on :: forall a b c. (b -> b -> c) -> (a -> b) -> a -> a -> c
on op f = \x y -> f x `op` f y

calcValue :: forall a. Env Value -> (Number -> Number -> a) -> Term -> Term -> a
calcValue e op = on op (\x -> case valueOf e x of
                           N num -> num
                           _     -> error "cannot peform arithmetic on non-numbers")

add :: Term -> Term -> Term
add x y = Sub x (Sub (Num 0.0) y)

t0 :: Term
t0 = Num 5.0

yComb :: Term
yComb = (Lam "rec"
         (App
          (Lam "foo"
           (App (Var "rec")
            (Lam "a" (App (App (Var "foo") (Var "foo")) (Var "a")))))
         (Lam "foo"
           (App (Var "rec")
            (Lam "a" (App (App (Var "foo") (Var "foo")) (Var "a")))))))

fact :: Term
fact = App yComb factBase where
  factBase = Lam "fact"
             (Lam "num"
              (If (Equ (Num 0.0) (Var "num"))
               (Num 1.0)
               (Mul (Var "num")
                (App (Var "fact")
                 (Sub (Var "num") (Num 1.0))))))

main = do
  logShow $ valueOf empty (App fact t0)
  -- logShow $ valueOf empty t0
  -- logShow $ valueOf empty (Mul t0 t0)
  -- logShow $ valueOf empty (Equ t0 t0)
  -- logShow $ valueOf empty (Equ t0 (Num 0.0))
  
