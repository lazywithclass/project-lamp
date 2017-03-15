---
layout: page
permalink: /chapter3/
custom_js:
- jquery.min
- anchor.min
- ace.min
- mode-haskell.min
- bundle
- index
---

## Chapter 3 - Continuing with Style

{%pagination chapter2#%}

In this chapter, we introduce *continuations* and writing functions in *continuation passing style* (CPS). We also discuss the reasons for writing CPSed programs.

### 1. Continuation Passing Style
In essence, a continuation is a higher-order function that abstracts over an extended content for performing a certain computation. This is much more easily explained in a functional language, since we can treat continuations simply as a special form of accumulator, where the value being "accumulated" is a function.

#### a. Callback Everyday -- Continuations
<!-- Convert a few basic functions -->
As we mentioned, a continuation is a higher-order function and writing in CPS is synonymous with using a function as an accumulator.

With this in mind, let's take a few steps back and recall writing in APS. In Chapter 1, we described how to convert a generally recursive definition into one that incorporates APS. To reiterate, here is the definition of `sum` written using general recursion:
```haskell
sum :: List Int -> Int
sum Nil    = 0
sum (x:xs) = x + (sum xs)
```
To convert `sum` into its APS equivalent, we add a parameter, representing an accumulated value, update its value during every recursive step, then return it once the base case is reached.
```haskell
sum :: List Int -> Int
sum xs = sumAcc xs 0
  where sumAcc Nil acc    = acc
        sumAcc (x:xs) acc = sumAcc (acc + x) xs
```
From here, translating an APSed program to a CPSed equivalent requires that we abstract over the accumulator by replacing it with a higher-order function, which gives us the following preliminary type definition for the CPS equivalent of `sum`, `sumCPS`:
```haskell
sumCPS :: List Int -> (... -> ...) -> Int
```

To derive the appropriate type for this function, we must do the following:

1. Determine the type of the final return value.
2. Determine the type of the recursive expression.

In this example, we know that `sum` should return an `Int`. Thus, we know the type of our continuation should *also* return an `Int`.
```haskell
sumCPS :: List Int -> (... -> Int) -> Int
```
Next, we need to determine the type of continuation's parameter, which we can determine by inspecting the type of the value we return for `sum`'s recursive case. In this case, the type is `Int`.
```haskell
sumCPS :: List Int -> (Int -> Int) -> Int
```
We then implement this function as follows:
{% repl_only sumcps#sum :: List Int -> Int
sum xs = sumCPS xs id
  where sumCPS Nil k    = k 0
        sumCPS (x:xs) k =
          sumCPS xs (\acc -> k (acc + x))%}

<!-- todo: explain this and id as base -->

with input List `(1:2:3:Nil)`
```haskell
-- Recursive cases: Continuations are extended
id
(\acc -> id (acc + 1))
(\acc -> (\acc -> id (acc + 1)) (acc + 2))
(\acc -> (\acc -> (\acc -> id (acc + 1)) (acc + 2)) (acc + 3))
-- Base case: Continuations are applied
(\acc -> (\acc -> (\acc -> id (acc + 1)) (acc + 2)) (acc + 3)) 0
(\acc -> (\acc -> id (acc + 1)) (acc + 2)) 3
(\acc -> id (acc + 1)) 5
id 6
-- Final continuation is applied
id 6
6
```

#### b. One Step at a Time -- Control Flow
<!-- explicit order of operations -->
<!-- near stateful computation -->

#### c. If You Squint Your Eyes -- Tail Calls
<!-- calling in tail position -->
<!-- graze on what writing in this way looks like -->

### 2. CPS the Interpreter -- Implementation
<!-- interpreter goes here -->
{% basic_hidden terms#instance showEnv :: Show a => Show (Env a) where
  show env = show' env true where
    show' EmptyEnv b | b         = "{}"
                     | otherwise = "}"
    show' (Ext e env) true =
      "{" <> e.name <> ": (" <>
      show e.val <> ")" <>
      show' env false
    show' (Ext e env) x =
      ", " <> e.name <> ": (" <>
      show e.val <> ")" <>
      show' env x

data Env a = EmptyEnv
           | Ext { name :: Name, val :: a } (Env a)

lookUp :: forall a. Env a -> Name -> a
lookUp EmptyEnv n = error $ "unbound variable: " <> show n
lookUp (Ext e env) n | n == e.name = e.val
                     | otherwise   = lookUp env n

extend :: forall a. Name -> a -> Env a -> Env a
extend n v = Ext { name : n, val : v }
instance showTerm :: Show Term where
  show (Num n)     = show n
  show (Sub x y)   = "(" <> show x <> " - " <> show y <> ")"
  show (Mul x y)   = "(" <> show x <> " * " <> show y <> ")"
  show (IsZero x)  = "(zero? " <> show x <> ")"
  show (If x y z)  =
    "If " <> show x <>
    " then " <> show y <>
    " else " <> show z
  show (Var n)     = n
  show (Lam n x)   =
    "(λ(" <> n <> ") . " <> show x <> ")"
  show (App x y)   =
    "(" <> show x <> " " <> show y <> ")"
type Name = String
data Term = Num Number
          | Sub Term Term
          | Mul Term Term
          | IsZero Term
          | If Term Term Term
          | Var Name
          | Lam Name Term
          | App Term Term
instance showValueC :: Show ValueC where
  show (NC x) = "NC " <> show x-- .n
  show (BC x) = "BC " <> show x-- .b
  show (FC (Closure clos)) =
    "Function from " <> clos.name <>
    " returns " <> show clos.body <>
    ", with context " <> show clos.env#newtype Closure = Closure {
  name  :: Name,
  body :: Term,
  env  :: Env ValueC
}

data ValueC = NC Number
            | BC Boolean
            | FC Closure%}

{% basic cpshelpers#onC :: forall a b c r.
       (b -> b -> c) -> (a -> (b -> r) -> r) ->
       a -> a -> (c -> r) -> r
onC op f x y return =
  f x $ \x ->
  f y $ \y ->
  return $ x `op` y

calcValueC :: Env ValueC -> (Number -> Number -> Number) ->
              Term -> Term -> (Number -> ValueC) -> ValueC
calcValueC e op =
  onC op $ \a return ->
  interpC e a $ \a ->
  case a of
    NC num -> return num
    _      ->
      error "arithmetic on non-number"%}

{% basic closfuns#applyClosure :: Closure -> ValueC -> (ValueC -> ValueC) -> ValueC
applyClosure (Closure clos) rat =
  interpC (extend clos.name rat clos.env) clos.body

makeClosure :: Name -> Term -> Env ValueC -> Closure
makeClosure n b e = Closure { name : n, body : b, env : e }%}

{% repl_only interpC#interpC :: Env ValueC -> Term -> (ValueC -> ValueC) -> ValueC
interpC _ (Num i) return    =
  return $ NC i
interpC e (Sub x y) return  =
  calcValueC e (-) x y $ \r ->
  return $ NC r
interpC e (Mul x y) return  =
  calcValueC e (*) x y $ \r ->
  return $ NC r
interpC e (IsZero x) return =
  interpC e x $ \x ->
  return <<< BC $
  case x of
    NC n -> n == 0.0
    _    -> false
interpC e (If x y z) return =
  interpC e x $ \x ->
  case x of
    BC bool ->
      if bool
      then interpC e y return
      else interpC e z return
    _       -> interpC e y return
interpC e (Var x) return   =
  return $ lookUp e x
interpC e (Lam n b) return =
  return $ FC (makeClosure n b e)
interpC e (App l r) return =
  interpC e l $ \l ->
  case l of
    FC foo ->
      interpC e r $ \val ->
      applyClosure foo val return
    _      -> error "applied non-function value"%}

```haskell
interpC EmptyEnv (App (Lam "x" (Lam "y" (Var "x"))) (Num 6.0)) id
==
interpC EmptyEnv (Lam "x" (Lam "y" (Var "x"))) $ \l ->
  case l of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value"
== cont is applied
\l ->
  case l of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value" $ 
FC (makeClosure "x" (Lam "y" (Var "x")) EmptyEnv)
==
case FC (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value"
==
interpC EmptyEnv (Num 6.0) $ \val ->
applyClosure (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) val id
==
\val ->
  applyClosure (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) val id $
NC 6.0
==
applyClosure (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) (NC 6.0) id
==
interpC (extend "x" (NC 6.0) EmptyEnv) (Lam "y" (Var "x")) id
== 
id $ FC (makeClosure "y" (Var "x") (Ext { name: "x", val: (NC 6.0) } EmptyEnv))
==
FC (makeClosure "y" (Var "x") (Ext { name: "x", val: (NC 6.0) } EmptyEnv))
```

## Exercises:

#### i. CPS Basic Functions
#### ii. From CPS to State Machine

{%pagination chapter2#%}
