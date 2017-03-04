module Main where

import Prelude
import Data.List
import Data.Tuple
import Data.Maybe
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
on :: forall a b c. (b -> b -> c) -> (a -> b) ->
      a -> a -> c
on op f = \x y -> f x `op` f y

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

instance showTerm :: Show Term where
  show (Num n)    = show n
  show (Sub x y)  = show x <> " - " <> show y
  show (Mul x y)  = show x <> " * " <> show y
  show (Equ x y)  = show x <> " == " <> show y
  show (If x y z) =
    "If " <> show x <>
    " then " <> show y <>
    " else " <> show z
  show (Var n)     = show n
  show (Let n x y) =
    "let " <> show n <>
    " = " <> show x <>
    " in " <> show y
  show (Lam n x)   =
    "(\\" <> show n <> " -> " <> show x <> ")"
  show (App x y)   =
    "(" <> show x <> " " <> show y <> ")"

data Env a = EmptyEnv
           | Ext { name :: Name, val :: a } (Env a)

instance showEnv :: Show a => Show (Env a) where
  show EmptyEnv = "|EMP|"
  show (Ext entry env) = "(" <> show entry.name <>
                         "," <> show entry.val <> ")" <>
                         show env
    
empty :: forall a. Env a
empty = EmptyEnv

extend :: forall a. Name -> a -> Env a -> Env a
extend n v = Ext { name : n, val : v }

lookUp :: forall a. Env a -> Name -> a
lookUp EmptyEnv n = error $ "unbound variable: " <> show n
lookUp (Ext e env) n | n == e.name = e.val
                     | otherwise   = lookUp env n

-- Base interpreter
data Value = N Number
           | B Boolean
           | F (Value -> Value)

instance showValue :: Show Value where
  show (N x) = "N " <> show x-- .n
  show (B x) = "B " <> show x-- .b
  show (F _) = "Function"

valCase :: (Number -> Value) -> (Boolean -> Value) ->
           ((Value -> Value) -> Value) -> Value -> Value  
valCase nv bv fv v =
  case v of
    N num -> nv num
    B boo -> bv boo
    F foo -> fv foo

-- todo : fix the infer value thing
valueOf :: Env Value -> Term -> Value
valueOf e (Var x)     = lookUp e x
valueOf _ (Num i)     = N i
valueOf e (Sub x y)   = N (calcValue e (-) x y)
valueOf e (Mul x y)   = N (calcValue e (*) x y)
valueOf e (Equ x y)   = B (calcValue e (==) x y)
valueOf e (Let x v b) = valueOf (extend x (valueOf e v) e) b
valueOf e (If x y z)  = case valueOf e x of
  B boo -> if boo then valueOf e y else valueOf e z
  _     -> valueOf e x -- every other value is truthy!
valueOf e (Lam v b) = F (\a -> (valueOf (extend v a e) b))
valueOf e (App l r) =
  case valueOf e l of
    F foo -> foo $ valueOf e r
    _     -> error $ "cannot apply non function value"

calcValue :: forall a. Env Value -> (Number -> Number -> a) ->
             Term -> Term -> a
calcValue e op =
  on op (\x -> case valueOf e x of
            N num -> num
            _     -> error "cannot peform arithmetic on non-numbers")

-- defunctionalized interpreter
newtype FuncD = FuncD {
  var  :: Name,
  body :: Term,
  env  :: Env ValueD
  }

data ValueD = ND Number
            | BD Boolean
            | FD FuncD

instance showValueD :: Show ValueD where
  show (ND x) = "ND " <> show x-- .n
  show (BD x) = "BD " <> show x-- .b
  show (FD (FuncD clos)) =
    "Function from " <> show clos.var <>
    ", returns (" <> show clos.body <>
    "), with context " <> show clos.env

applyFD :: FuncD -> ValueD -> ValueD
applyFD (FuncD clos) rat =
  valueOfD (extend clos.var rat clos.env) clos.body

makeFD :: Name -> Term -> Env ValueD -> FuncD
makeFD n t e = FuncD { var : n, body : t, env : e }

valueOfD :: Env ValueD -> Term -> ValueD
valueOfD e (Var x)     = lookUp e x
valueOfD _ (Num i)     = ND i
valueOfD e (Sub x y)   = ND (calcValueD e (-) x y)
valueOfD e (Mul x y)   = ND (calcValueD e (*) x y)
valueOfD e (Equ x y)   = BD (calcValueD e (==) x y)
valueOfD e (Let x v b) = valueOfD (extend x (valueOfD e v) e) b
valueOfD e (If x y z)  = case valueOfD e x of
  BD bool -> if bool then valueOfD e y else valueOfD e z
  _       -> valueOfD e y 
valueOfD e (Lam v b) = FD (makeFD v b e)
valueOfD e (App l r) = case valueOfD e l of
  FD foo -> applyFD foo (valueOfD e r)
  _      -> error "cannot apply non function value"

calcValueD :: forall a. Env ValueD -> (Number -> Number -> a) ->
              Term -> Term -> a
calcValueD e op =
  on op (\x -> case valueOfD e x of
            ND num -> num
            _      -> error "cannot peform arithmetic on non-numbers")

-- CPS interpreter
newtype FuncC = FuncC {
  var  :: Name,
  body :: Term,
  env  :: Env ValueC
  }

data ValueC = NC Number
            | BC Boolean
            | FC FuncC

instance showValueC :: Show ValueC where
  show (NC x) = "NC " <> show x-- .n
  show (BC x) = "BC " <> show x-- .b
  show (FC (FuncC clos)) =
    "Function from " <> show clos.var <>
    ", returns (" <> show clos.body <>
    "), with context " <> show clos.env

emptyK :: forall a. a -> a
emptyK x = x

applyFC :: FuncC -> ValueC -> (ValueC -> ValueC) -> ValueC
applyFC (FuncC clos) rat =
  valueOfC (extend clos.var rat clos.env) clos.body

makeFC :: Name -> Term -> Env ValueC -> FuncC
makeFC n t e = FuncC { var : n, body : t, env : e }

valueOfC :: Env ValueC -> Term -> (ValueC -> ValueC) -> ValueC
valueOfC e (Var x) return    =
  return $ lookUp e x
valueOfC _ (Num i) return    =
  return $ NC i
valueOfC e (Sub x y) return  =
  calcValueC e (-) x y $ \r ->
  return $ NC r
valueOfC e (Mul x y) return  =
  calcValueC e (*) x y $ \r ->
  return $ NC r
valueOfC e (Equ x y) return  =
  calcValueC e (==) x y $ \r ->
  return $ BC r
valueOfC e (Let x v b) return =
  valueOfC e v $ \v' ->
  valueOfC (extend x v' e) b return
valueOfC e (If x y z) return =
  valueOfC e x $ \x' ->
  case x' of
    BC bool ->
      if bool
      then valueOfC e y return
      else valueOfC e z return
    _       -> valueOfC e y return
valueOfC e (Lam v b) return =
  return $ FC (makeFC v b e)
valueOfC e (App l r) return =
  valueOfC e l $ \l' ->
  case l' of
    FC foo ->
      valueOfC e r $ \r' ->
      applyFC foo r' return
    _      -> error "cannot apply non function value"

onC :: forall a b c r. (b -> b -> c) -> (a -> (b -> r) -> r) ->
       a -> a -> (c -> r) -> r    
onC op f x y return =
  f x $ \x' ->
  f y $ \y' ->
  return $ x' `op` y'

calcValueC :: forall a. Env ValueC -> (Number -> Number -> a) ->
              Term -> Term -> (a -> ValueC) -> ValueC
calcValueC e op =
  onC op (\a return ->
           valueOfC e a $ \a' ->
           case a' of
             NC num -> return num
             _      -> error "cannot peform arithmetic on non-numbers")

-- Testing
add :: Term -> Term -> Term
add x y = Sub x (Sub (Num 0.0) y)

t0 :: Term
t0 = Num 10.0

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
  logShow $ valueOf empty (Lam "x" (Lam "y" (Var "x")))
  logShow $ valueOf empty (App fact t0)
  logShow $ valueOfD empty (Lam "x" (Lam "y" (Var "x")))
  logShow $ valueOfD empty (App fact t0)
  logShow $ valueOfC empty (Lam "x" (Lam "y" (Var "x"))) emptyK
  logShow $ valueOfC empty (App fact t0) emptyK

  
